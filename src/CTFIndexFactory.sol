// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {IConditionalTokens} from "./interfaces/IConditionalTokens.sol";
import {CTFIndexToken} from "./CTFIndex.sol";

// @dev
// Invariant conditions:
// 1. If the set of positionids is the same, and the metadata and ctf addresses are the same, calculate the same indextoken.
// 2. An indextoken is issued and can be withdrawn in a 1:1 ratio with the position token it contains.
// 3. An indextoken cannot have two or more positions under the same conditionid.
contract CTFIndexFactory {

    event IndexCreated(
        address indexed index,
        bytes32 indexed salt,
        uint256[] indexSets,
        bytes metadata
    );


    IConditionalTokens public immutable ctf;
    address public immutable collateral;
    mapping(bytes32 => address) public getIndex;

    error LengthMismatch();
    error InvalidOrder();
    error InvalidIndexSet();
    error IndexAlreadyExists();
    error InvalidCondition();

    constructor(address _ctf, address _collateral) {
        ctf = IConditionalTokens(_ctf);
        collateral = _collateral;
    }

    function bundlePosition(
        bytes32[] calldata conditionIds,
        uint256[] calldata indexSets,
        bytes calldata metadata
    ) external returns (address index) {

        (, , 
            bytes32 salt, 
            string memory name, 
            string memory symbol,
            bytes memory initCode
        ) = _preparePosition(conditionIds, indexSets, metadata);


        predicted = address(
            uint160(uint256(
            keccak256(
                abi.encodePacked(
                    bytes1(0xff), address(this), salt, keccak256(initCode)
                )
            )
        )));

        if(predicted.code.length != 0) revert IndexAlreadyExists();

        //CREATE2 deploy
        assembly {
            let ptr := add(initCode, 0x20)
            let len := mload(initCode)
            index := create2(0, ptr, len, salt)
            if iszero(index) { revert(0, 0) }
        }

        CTFIndexToken(index).initialize(
            indexSets, 
            conditionIds, 
            metadata,
            collateral,
            address(ctf)
        );

        getIndex[salt] = index;
        emit IndexCreated(index, salt, indexSets, metadata);
    }

    function calculateIndexAddress(
        bytes32[] calldata conditionIds,
        uint256[] calldata indexSets,
        bytes calldata metadata
    ) external view returns (address predicted) {

        (, , 
            bytes32 salt, 
            string memory name, 
            string memory symbol,
            bytes memory initCode
        ) = _preparePosition(conditionIds, indexSets, metadata);


        predicted = address(
            uint160(uint256(
            keccak256(
                abi.encodePacked(
                    bytes1(0xff), address(this), salt, keccak256(initCode)
                )
            )
        )));
    }

    function _preparePosition(
        bytes32[] calldata conditionIds,
        uint256[] calldata indexSets,
        bytes calldata metadata
    )
        internal
        view
        returns (
            bytes32 salt,
            string memory name,
            string memory symbol,
            bytes memory initCode
        )
    {
            bytes32 salt;
            unchecked {
                for (uint256 i; i < conditionIds.length; ++i) {
                    salt ^= keccak256(abi.encodePacked(conditionIds[i], indexSets[i]));
                }
                salt ^= bytes32(conditionIds.length);       // mix in cardinality
                salt ^= keccak256(metadata); 
            }

            string memory suffix = Strings.toHexString(uint256(salt));
            name= string(abi.encodePacked("CTFIndex-", suffix));
            symbol = string(abi.encodePacked("CTFI.",suffix));
            initCode = abi.encodePacked(
                type(CTFIndexToken).creationCode,
                abi.encode(name, symbol)            // constructor args
            );
    }

}


contract CTFIndexToken is ERC20, IERC1155Receiver {
    address public immutable factory;
    uint256[] internal _indexSets;
    bytes32[] internal _conditionIds;
    uint256 internal _createdAt;
    bytes internal _metadata;
    address internal collateral;
    IConditionalTokens internal ctf;

    error OnlyFactory();
    error AlreadyInitialised();
    error LengthMismatch();

    modifier onlyFactory() {
        if (msg.sender != factory) revert OnlyFactory();
        _;
    }

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        factory = msg.sender;
    }

    /**
     * @notice Store sorted `(conditionId, indexSet)` arrays after deployment.
     * @dev    Factory sorts and validates; token only records.
     */
    function initialize(
        uint256[] calldata indexSets,
        bytes32[] calldata conditionIds,
        bytes calldata metadata_,
        address collateral_,
        address ctf_
    ) external onlyFactory {
        if (_createdAt != 0) revert AlreadyInitialised();
        uint256 n = indexSets.length;
        if (n == 0 || n != conditionIds.length) revert LengthMismatch();

        _indexSets = indexSets;
        _conditionIds = conditionIds;
        _metadata = metadata_;
        _createdAt = block.timestamp;
        collateral = collateral_;
        ctf = IConditionalTokens(ctf_);
    }

    function mint(uint256 amount) external {
        uint256 len = _indexSets.length;

        uint256[] memory ids = new uint256[](len);
        uint256[] memory amts = new uint256[](len);
        unchecked {
            for (uint256 i = 0; i < len; ++i) {
                ids[i] = _positionId(_conditionIds[i], _indexSets[i]);
                amts[i] = amount;
            }
        }

        ctf.safeBatchTransferFrom(msg.sender, address(this), ids, amts, "");
        _mint(msg.sender, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        uint256 len = _indexSets.length;

        uint256[] memory ids = new uint256[](len);
        uint256[] memory amts = new uint256[](len);
        unchecked {
            for (uint256 i = 0; i < len; ++i) {
                ids[i] = _positionId(_conditionIds[i], _indexSets[i]);
                amts[i] = amount;
            }
        }
        ctf.safeBatchTransferFrom(address(this), msg.sender, ids, amts, "");
    }

    function getIndexSets() external view returns (uint256[] memory) {
        return _indexSets;
    }
    function getConditionIds() external view returns (bytes32[] memory) {
        return _conditionIds;
    }
    function metadata() external view returns (bytes memory) {
        return _metadata;
    }
    function createdAt() external view returns (uint256) {
        return _createdAt;
    }

    function _positionId(bytes32 conditionId, uint256 indexSet) internal view returns (uint256) {
        return ctf.getPositionId(collateral, ctf.getCollectionId(bytes32(0), conditionId, indexSet));
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId;
    }
}

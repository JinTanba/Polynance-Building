// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract WCtf is ERC20 {
    address public immutable hub;

    constructor(string memory name_, string memory sym_, address hub_)
        ERC20(name_, sym_)
    {
        hub = hub_;
    }

    // Standard ERC‑20 precision
    function decimals() public pure override returns (uint8) { return 18; }

    function mint(address to, uint256 amt) external { 
        require(msg.sender == hub, "HUB_ONLY"); 
        _mint(to, amt); 
    }
    function burn(address from, uint256 amt) external { 
        require(msg.sender == hub, "HUB_ONLY"); 
        _burn(from, amt); 
    }
}

contract WrappedCTFFactory is IERC1155Receiver {
    using Strings for uint256;
    IERC1155 public immutable ctf;
    string constant wName = "Polymarket WrappedCTF";
    string constant wSymbol = "WrappedCTF";

    mapping(uint256 => address) public erc20OfId;

    event WrapperDeployed(uint256 indexed id, address wrapper);
    event Deposited(address indexed user, uint256 indexed id, uint256 amount);
    event Redeemed(address indexed user, uint256 indexed id, uint256 amount);

    constructor(address _ctf) { 
        ctf = IERC1155(_ctf); 
    }

    function deposit(uint256 id, uint256 amount) external  {
        require(amount > 0, "AMOUNT_ZERO");
        address w = _getOrDeployWrapper(id);

        ctf.safeTransferFrom(msg.sender, address(this), id, amount, "");
        WCtf(w).mint(msg.sender, amount * 1e18);
        emit Deposited(msg.sender, id, amount);
    }

    function redeem(uint256 id, uint256 amountPieces) external {
        require(amountPieces > 0, "AMOUNT_ZERO");
        address w = erc20OfId[id];
        require(w != address(0), "WRAPPER_NX");

        uint256 units = amountPieces * 1e18;
        WCtf(w).burn(msg.sender, units);
        ctf.safeTransferFrom(address(this), msg.sender, id, amountPieces, "");
        emit Redeemed(msg.sender, id, amountPieces);
    }

    function _getOrDeployWrapper(uint256 id) internal returns (address w) {
        w = erc20OfId[id];
        if (w != address(0)) return w;

        string memory name   = string.concat(wName, id.toString());
        string memory symbol = string.concat(wSymbol, id.toString());
        bytes memory bytecode = abi.encodePacked(
            type(WCtf).creationCode,
            abi.encode(name, symbol, address(this))
        );
        bytes32 salt = _saltFor(id);

        assembly {
            w := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(w) { revert(0, 0) }
        }
        erc20OfId[id] = w;
        emit WrapperDeployed(id, w);
    }


    function _calcWrapperAddress(uint256 id) internal view returns (address) {
        string memory name   = string.concat(wName, id.toString());
        string memory symbol = string.concat(wSymbol, id.toString());
        bytes memory bytecode = abi.encodePacked(
            type(WCtf).creationCode,
            abi.encode(name, symbol, address(this))
        );
        bytes32 salt = _saltFor(id);
        bytes32 initHash = keccak256(bytecode);
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, initHash));
        return address(uint160(uint256(hash)));
    }

    function predictedWrapper(uint256 id) external view returns (address) {
        return _calcWrapperAddress(id);
    }

    function _saltFor(uint256 id) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(address(ctf), id));
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 iid) public pure override returns (bool) {
        return iid == type(IERC1155Receiver).interfaceId;
    }
}

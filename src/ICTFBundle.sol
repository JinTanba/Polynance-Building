// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*//////////////////////////////////////////////////////////////
                        FACTORY INTERFACE
//////////////////////////////////////////////////////////////*/

/**
 * @title ICTFIndexFactory
 * @notice Deploys deterministic “bundle” ERC-20 tokens that track a balanced
 *         basket of Gnosis CTF ERC-1155 position tokens.
 *         - Every bundle address is derived with CREATE2 so it can be predicted
 *           off-chain before deployment.
 *         - The factory may be upgradeable; each index it spawns is immutable.
 */
interface ICTFIndexFactory {
    /**
     * @dev Emitted after a successful deployment.
     * @param index      Address of the new index ERC-20 contract.
     * @param bundleHash keccak256(abi.encodePacked(ctf, ids, metadata)).
     * @param ids        Strictly-ascending list of constituent token IDs.
     * @param metadata   Permanent bytes blob stored in the index (name, theme…).
     */
    event IndexCreated(
        address indexed index,
        bytes32 indexed bundleHash,
        uint256[] ids,
        bytes metadata
    );

    /**
     * @notice Deploy a new index bundle.
     * @dev Reverts if:
     *      - `ids` are not sorted or contain duplicates,
     *      - two complementary outcomes of the same condition are present, or
     *      - any ID uses a non-USDC collateral token (USDC-only basket rule).
     * @param ids       Sorted CTF ERC-1155 IDs (one unit of each forms 1 bundle).
     * @param metadata  Arbitrary descriptive data (stored immutably on the index).
     * @return index    Address of the freshly-deployed ERC-20 bundle token.
     */
    function createIndex(
        uint256[] calldata ids,
        bytes calldata metadata
    ) external returns (address index);

    /**
     * @notice Pure / view helper that returns the address where the bundle would
     *         be deployed for the given parameters.
     * @dev Used by UIs and relayers to interact with a bundle pre-deployment.
     */
    function predictIndexAddress(
        uint256[] calldata ids,
        bytes calldata metadata
    ) external view returns (address predicted);
}

/*//////////////////////////////////////////////////////////////
                         INDEX INTERFACE
//////////////////////////////////////////////////////////////*/

/**
 * @title ICTFIndex
 * @notice ERC-20 representing 1-for-1 ownership of:
 *         - one unit of every *unsettled* CTF position in the basket, plus
 *         - any USDC already claimed from positions that have resolved.
 *
 * Key invariants
 * ---------------
 * 1. `totalSupply ≤ Σ(unsettledUnits) + collateralUnits`
 * 2. Once the first constituent settles, `mint()` is PERMANENTLY disabled
 *    so supply can never exceed backing.
 * 3. `convert()` may be called by *anyone*, any number of times; it is
 *    idempotent per ID (`settled[id] == true` after first conversion).
 *
 * Users may call `burn()` at ANY time.
 *   - They receive pro-rata USDC for settled IDs
 *   - …and pro-rata ERC-1155 tokens for IDs still awaiting settlement.
 *
 * The contract itself holds no price oracle — valuation is an off-chain concern.
 */
interface ICTFIndex /* is IERC20, IERC1155Receiver */ {
    /*===============================  EVENTS  ===============================*/

    /// A constituent ID has been redeemed into USDC via {convert}.
    event Converted(uint256 indexed id, uint256 usdcIn, address indexed caller);

    /// Fired exactly once, the first time any ID in the basket settles.
    event MintingFrozen();

    /*===========================  VIEW FUNCTIONS  ===========================*/

    /// @return ids  Strictly-ascending array of all constituent token IDs.
    function getIds() external view returns (uint256[] memory ids);

    /// @return meta  Immutable metadata blob set at deployment.
    function getMetadata() external view returns (bytes memory meta);

    /// @return true if *all* constituents have resolved and been converted.
    function isFullySettled() external view returns (bool);

    /**
     * @notice Preview the assets a user would receive for burning `bundleAmount`.
     * @dev Convenience helper for front-ends; makes no state changes.
     */
    function previewBurn(
        uint256 bundleAmount
    )
        external
        view
        returns (
            uint256 usdcOut,              // pro-rata USDC
            uint256[] memory ids,         // returned token IDs (=getIds())
            uint256[] memory posOut       // pro-rata position amounts
        );

    /*========================  STATE-CHANGING LOGIC  ========================*/

    /**
     * @notice Mint bundle tokens while ALL constituents are still unsettled.
     * @param amount  Number of units for each ID to deposit
     *                (mints the same amount of bundle ERC-20).
     * @dev Reverts permanently once {MintingFrozen} has been emitted.
     */
    function mint(uint256 amount) external;

    /**
     * @notice Burn bundle tokens and receive exactly the caller’s share of:
     *         • any USDC already inside the contract, plus
     *         • any still-unsettled CTF position tokens.
     * @param amount  Bundle tokens to burn.
     */
    function burn(uint256 amount) external;

    /**
     * @notice Convert specified constituent IDs that have reached payout into
     *         USDC held internally by the bundle.
     * @dev - Callable by anyone (public good; bots will keep bundles current).
     *      - Safe to repeat: each ID can be converted only once.
     *      - Caller chooses batch size to fit within the gas limit.
     */
    function convert(uint256[] calldata ids) external;
}


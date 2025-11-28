// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title CarbonOffsetTokenization
 * @dev ERC20-like carbon offset token with mint (issue credits) and retire (burn offsets) mechanics
 * @notice Each token represents 1 unit of verified carbon offset; retired tokens are burned permanently
 */
contract CarbonOffsetTokenization {
    // --- ERC20-like state ---
    string public name = "Carbon Offset Token";
    string public symbol = "COFF";
    uint8  public decimals = 18;

    uint256 public totalSupply;
    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // --- Offsetting & certification state ---
    uint256 public totalRetired;

    struct Retirement {
        uint256 amount;
        string  retireeId;     // optional identifier (company/user ID)
        string  projectRef;    // reference to the underlying carbon project / certificate
        uint256 timestamp;
    }

    // account => list of retirements
    mapping(address => Retirement[]) public retirementsOf;

    // addresses allowed to mint new credits (e.g., registries or project verifiers)
    mapping(address => bool) public isMinter;

    // --- Events ---
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed holder, address indexed spender, uint256 value);
    event Minted(address indexed to, uint256 amount, string projectRef);
    event Retired(address indexed from, uint256 amount, string retireeId, string projectRef);
    event MinterUpdated(address indexed minter, bool approved);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyMinter() {
        require(isMinter[msg.sender], "Not minter");
        _;
    }

    constructor() {
        owner = msg.sender;
        isMinter[msg.sender] = true;
        emit MinterUpdated(msg.sender, true);
    }

    // --- ERC20 core ---

    function transfer(address to, uint256 value) external returns (bool) {
        require(to != address(0), "Zero address");
        require(balanceOf[msg.sender] >= value, "Balance too low");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(to != address(0), "Zero address");
        require(balanceOf[from] >= value, "Balance too low");
        require(allowance[from][msg.sender] >= value, "Allowance too low");

        allowance[from][msg.sender] -= value;
        balanceOf[from] -= value;
        balanceOf[to] += value;

        emit Transfer(from, to, value);
        return true;
    }

    // --- Minting & retiring ---

    /**
     * @dev Mint new carbon offset tokens to `to` after verification of underlying credits
     * @param to Recipient address
     * @param amount Amount to mint
     * @param projectRef Human-readable reference to the carbon project/certificate
     */
    function mint(
        address to,
        uint256 amount,
        string calldata projectRef
    ) external onlyMinter {
        require(to != address(0), "Zero address");
        require(amount > 0, "Amount = 0");

        totalSupply += amount;
        balanceOf[to] += amount;

        emit Minted(to, amount, projectRef);
        emit Transfer(address(0), to, amount);
    }

    /**
     * @dev Retire (burn) carbon offsets from msg.sender, permanently taking them out of circulation
     * @param amount Amount to retire
     * @param retireeId Optional identifier for who is claiming the offset
     * @param projectRef Optional reference to project or purpose for retirement
     */
    function retire(
        uint256 amount,
        string calldata retireeId,
        string calldata projectRef
    ) external {
        require(amount > 0, "Amount = 0");
        require(balanceOf[msg.sender] >= amount, "Balance too low");

        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        totalRetired += amount;

        retirementsOf[msg.sender].push(
            Retirement({
                amount: amount,
                retireeId: retireeId,
                projectRef: projectRef,
                timestamp: block.timestamp
            })
        );

        emit Retired(msg.sender, amount, retireeId, projectRef);
        emit Transfer(msg.sender, address(0), amount);
    }

    /**
     * @dev Get all retirement records for an account
     */
    function getRetirementsOf(address account)
        external
        view
        returns (Retirement[] memory)
    {
        return retirementsOf[account];
    }

    /**
     * @dev Add or remove authorized minter
     */
    function setMinter(address minter, bool approved) external onlyOwner {
        isMinter[minter] = approved;
        emit MinterUpdated(minter, approved);
    }

    /**
     * @dev Transfer contract ownership
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        address prev = owner;
        owner = newOwner;
        emit OwnershipTransferred(prev, newOwner);
    }
}

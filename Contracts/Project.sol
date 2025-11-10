// SPDX-License-Identifier: MIT
// License: MIT ensures open-source compliance and allows reuse under permissive terms.
// Solidity version pragma ensures compatibility with compiler version 0.8.x

pragma solidity ^0.8.0;

/**
 * @title Carbon Credit Fractional Ownership
 * @dev A smart contract for fractionalizing and trading carbon credits
 */

struct CarbonCredit {
    uint256 id;               // Unique identifier for the credit
    string projectName;       // Name of the carbon project
    uint256 totalTons;        // Total carbon tons available
    uint256 availableTons;    // Tons still available for sale
    uint256 pricePerTon;      // Price in wei per ton
    address owner;            // Project creator or owner
    bool verified;            // Verification flag for project validity
    bool retired;             // Whether credit has been fully retired
}

// ---------------------------------------------------------------------------
// State Variables
// ---------------------------------------------------------------------------
    uint256 public creditCount;
    mapping(uint256 => CarbonCredit) public carbonCredits;
    // Tracks how many tons of a specific carbon credit each user owns
    mapping(address => mapping(uint256 => uint256)) public userCreditBalances;


// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------
    //event CreditCreated(uint256 indexed creditId, string projectName, uint256 totalTons, uint256 pricePerTon);
    //event CreditPurchased(uint256 indexed creditId, address indexed buyer, uint256 tons, uint256 totalCost);
    //event CreditRetired(uint256 indexed creditId, address indexed retiree, uint256 tons);
    
    /// @notice Emitted when a new carbon credit is created
    /// @param creditId The unique ID assigned to the carbon credit
    /// @param projectName The name of the carbon offset project
    /// @param totalTons Total number of CO2 tons represented
    /// @param pricePerTon Price in wei for each ton of CO2 offset

    event CreditCreated(
        uint256 indexed creditId,
        string projectName,
        uint256 totalTons,
        uint256 pricePerTon
    );
    
    /// @notice Emitted when a user purchases fractional carbon credits
    /// @param creditId The ID of the carbon credit being purchased
    /// @param buyer The address of the buyer
    /// @param tons The number of tons purchased
    /// @param totalCost The total amount paid in wei
    event CreditPurchased(
        uint256 indexed creditId,
        address indexed buyer,
        uint256 tons,
        uint256 totalCost
    );
    
    /// @notice Emitted when a user retires carbon credits permanently
    /// @param creditId The ID of the retired carbon credit
    /// @param retiree The address of the person retiring the credit
    /// @param tons The number of tons retired
    event CreditRetired(
        uint256 indexed creditId,
        address indexed retiree,
        uint256 tons
    );
    
// ---------------------------------------------------------------------------
// Core Functionalities
// ---------------------------------------------------------------------------

    /**
     * @notice Creates a new verified carbon credit token for a project.
     * @dev Initializes a CarbonCredit struct and assigns ownership to the creator.
     * @param _projectName Name of the carbon offset project.
     * @param _totalTons Total tons of CO2 offset.
     * @param _pricePerTon Price per ton in wei.
     * @return The ID of the newly created carbon credit.
     */
    function createCarbonCredit(
        string calldata _projectName, // Using calldata for gas efficiency (read-only external input)
        uint256 _totalTons,
        uint256 _pricePerTon
    ) external returns (uint256) { // Changed to external for gas optimization
        require(_totalTons > 0, "Total tons must be greater than 0.");
        require(_pricePerTon > 0, "Price per ton must be greater than 0.");

        creditCount++;
        
        carbonCredits[creditCount] = CarbonCredit({
            id: creditCount,
            projectName: _projectName,
            totalTons: _totalTons,
            availableTons: _totalTons,
            pricePerTon: _pricePerTon,
            owner: msg.sender,
            verified: true,
            retired: false
        });
        
        emit CreditCreated(creditCount, _projectName, _totalTons, _pricePerTon);
        
        return creditCount;
    }
    
     /**
     * @notice Allows a user to purchase fractional ownership of a carbon credit.
     * @dev Transfers payment to the project owner and updates available tons.
     * @param _creditId The ID of the carbon credit to purchase.
     * @param _tons The number of tons to purchase.
     */
    function purchaseCarbonCredit(uint256 _creditId, uint256 _tons) public payable {
        CarbonCredit storage credit = carbonCredits[_creditId];
        
        require(credit.id != 0, "Credit does not exist.");
        require(credit.verified, "Credit not verified.");
        require(!credit.retired, "Credit has been retired.");
        require(_tons > 0 && _tons <= credit.availableTons, "Invalid ton amount.");
        
        uint256 totalCost = _tons * credit.pricePerTon;
        require(msg.value >= totalCost, "Insufficient payment.");
        
        // Update balances
        credit.availableTons -= _tons;
        userCreditBalances[msg.sender][_creditId] += _tons;
        
        // Transfer payment to credit owner
        payable(credit.owner).transfer(totalCost);
        
        // Refund excess payment
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
        
        emit CreditPurchased(_creditId, msg.sender, _tons, totalCost);
    }
    /**
     * @notice Retires a specified amount of carbon credits from circulation.
     * @dev Reduces the user's balance permanently to reflect retirement.
     * @param _creditId The ID of the carbon credit being retired.
     * @param _tons The number of tons to retire.
     */
    function retireCarbonCredit(uint256 _creditId, uint256 _tons) public {
        require(userCreditBalances[msg.sender][_creditId] >= _tons, "Insufficient credit balance.");
        require(_tons > 0, "Must retire at least some tons.");
        
        CarbonCredit storage credit = carbonCredits[_creditId];
        require(credit.id != 0, "Credit does not exist.");
        
        // Burn the credits
        userCreditBalances[msg.sender][_creditId] -= _tons;
        
        emit CreditRetired(_creditId, msg.sender, _tons);
    } 
    /**
     * @notice Returns the remaining balance of a user's fractional credits.
     * @param _user Address of the user.
     * @param _creditId ID of the carbon credit.
     * @return The balance (in tons) owned by the user.
     */
// ---------------------------------------------------------------------------
// View / Getter Functions
// ---------------------------------------------------------------------------

    function getUserBalance(address _user, uint256 _creditId) public view returns (uint256) {
        return userCreditBalances[_user][_creditId];
    }
    /**
     * @notice Returns full details of a specific carbon credit.
     * @param _creditId ID of the carbon credit.
     * @return projectName, totalTons, availableTons, pricePerTon, owner, verified, retired.
     */
    function getCreditDetails(uint256 _creditId) public view returns (
        string memory projectName,
        uint256 totalTons,
        uint256 availableTons,
        uint256 pricePerTon,
        address owner,
        bool verified,
        bool retired
    ) {
        CarbonCredit memory credit = carbonCredits[_creditId];
        return (
            credit.projectName,
            credit.totalTons,
            credit.availableTons,
            credit.pricePerTon,
            credit.owner,
            credit.verified,
            credit.retired
        );
    }
    /**
     * @notice Returns the total number of carbon credits created.
     * @dev Useful for querying the total available supply of projects.
     * @return The total count of carbon credits created so far.
     */
    function getTotalCredits() public view returns (uint256) {
        return creditCount;
    }
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    /**
     * @notice Checks if a specific carbon credit is available for purchase.
     * @dev Returns true if verified, not retired, and has available tons > 0.
     * @param _creditId ID of the carbon credit.
     * @return A boolean value indicating availability status.
     */
    function isCreditAvailable(uint256 _creditId) public view returns (bool) {
        CarbonCredit memory credit = carbonCredits[_creditId];
        return (credit.verified && !credit.retired && credit.availableTons > 0);
    }
    // ---------------------------------------------------------------------------
    // ETH Receive Function
    // ---------------------------------------------------------------------------
    
    /**
     * @notice Handles direct ETH transfers sent to the contract.
     * @dev Allows contract to safely receive ETH without executing any function.
     */
    receive() external payable {
        // Accept Ether transfers silently
}

}
  








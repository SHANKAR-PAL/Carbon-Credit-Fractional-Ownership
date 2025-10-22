// SPDX-License-Identifier: MIT
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

    // State variables
    uint256 public creditCount;
    mapping(uint256 => CarbonCredit) public carbonCredits;
    mapping(address => mapping(uint256 => uint256)) public userCreditBalances;
    
    // Events
    //event CreditCreated(uint256 indexed creditId, string projectName, uint256 totalTons, uint256 pricePerTon);
    //event CreditPurchased(uint256 indexed creditId, address indexed buyer, uint256 tons, uint256 totalCost);
    //event CreditRetired(uint256 indexed creditId, address indexed retiree, uint256 tons);
    // ---------------------------------------------------------------------------
    // Events
    // ---------------------------------------------------------------------------
    
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
    
    
    /**
     * @dev Creates a new carbon credit token
     * @param _projectName Name of the carbon offset project
     * @param _totalTons Total tons of CO2 offset
     * @param _pricePerTon Price per ton in wei
     */
// ----------------------
// Core Project Functions
// ----------------------

    function createCarbonCredit(
        string memory _projectName,
        uint256 _totalTons,
        uint256 _pricePerTon
    ) public returns (uint256) {
        require(_totalTons > 0, "Total tons must be greater than 0");
        require(_pricePerTon > 0, "Price per ton must be greater than 0");
        
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
     * @dev Purchase fractional carbon credits
     * @param _creditId ID of the carbon credit to purchase
     * @param _tons Amount of tons to purchase
     */
    function purchaseCarbonCredit(uint256 _creditId, uint256 _tons) public payable {
        CarbonCredit storage credit = carbonCredits[_creditId];
        
        require(credit.id != 0, "Credit does not exist");
        require(credit.verified, "Credit not verified");
        require(!credit.retired, "Credit has been retired");
        require(_tons > 0 && _tons <= credit.availableTons, "Invalid ton amount");
        
        uint256 totalCost = _tons * credit.pricePerTon;
        require(msg.value >= totalCost, "Insufficient payment");
        
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
     * @dev Retire carbon credits permanently (remove from circulation)
     * @param _creditId ID of the carbon credit to retire
     * @param _tons Amount of tons to retire
     */
    function retireCarbonCredit(uint256 _creditId, uint256 _tons) public {
        require(userCreditBalances[msg.sender][_creditId] >= _tons, "Insufficient credit balance");
        require(_tons > 0, "Must retire at least some tons");
        
        CarbonCredit storage credit = carbonCredits[_creditId];
        require(credit.id != 0, "Credit does not exist");
        
        // Burn the credits
        userCreditBalances[msg.sender][_creditId] -= _tons;
        
        emit CreditRetired(_creditId, msg.sender, _tons);
    }
    
    /**
     * @dev Get user's balance for a specific credit
     * @param _user Address of the user
     * @param _creditId ID of the carbon credit
     */
    function getUserBalance(address _user, uint256 _creditId) public view returns (uint256) {
        return userCreditBalances[_user][_creditId];
    }
    
    /**
     * @dev Get credit details
     * @param _creditId ID of the carbon credit
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
     * @dev Get total number of carbon credits created
     * @return The total count of credits created so far
     */
    function getTotalCredits() public view returns (uint256) {
        return creditCount;
    }
}
  








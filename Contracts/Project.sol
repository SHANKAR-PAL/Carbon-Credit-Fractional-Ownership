// SPDX-License-Identifier: MIT
// Solidity version pragma ensures compatibility with compiler version 0.8.x

pragma solidity ^0.8.0;

/**
 * @title Carbon Credit Fractional Ownership
 * @dev A smart contract for fractionalizing and trading carbon credits
 */
contract Project {
    
    // Struct to represent a Carbon Credit
    struct CarbonCredit {
        uint256 id;
        string projectName;
        uint256 totalTons;
        uint256 availableTons;
        uint256 pricePerTon;
        address owner;
        bool verified;
        bool retired;
    }
    
    // State variables
    uint256 public creditCounter;
    mapping(uint256 => CarbonCredit) public carbonCredits;
    mapping(address => mapping(uint256 => uint256)) public userCreditBalances;
    
    // Events
    event CreditCreated(uint256 indexed creditId, string projectName, uint256 totalTons, uint256 pricePerTon);
    event CreditPurchased(uint256 indexed creditId, address indexed buyer, uint256 tons, uint256 totalCost);
    event CreditRetired(uint256 indexed creditId, address indexed retiree, uint256 tons);
    
    /**
     * @dev Creates a new carbon credit token
     * @param _projectName Name of the carbon offset project
     * @param _totalTons Total tons of CO2 offset
     * @param _pricePerTon Price per ton in wei
     */
    function createCarbonCredit(
        string memory _projectName,
        uint256 _totalTons,
        uint256 _pricePerTon
    ) public returns (uint256) {
        require(_totalTons > 0, "Total tons must be greater than 0");
        require(_pricePerTon > 0, "Price per ton must be greater than 0");
        
        creditCounter++;
        
        carbonCredits[creditCounter] = CarbonCredit({
            id: creditCounter,
            projectName: _projectName,
            totalTons: _totalTons,
            availableTons: _totalTons,
            pricePerTon: _pricePerTon,
            owner: msg.sender,
            verified: true,
            retired: false
        });
        
        emit CreditCreated(creditCounter, _projectName, _totalTons, _pricePerTon);
        
        return creditCounter;
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
}

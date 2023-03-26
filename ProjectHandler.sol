//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
error Unauthorized();   //Mention of Error for notOwner(Unauthorized access)
error InsufficientBalance(uint256 available, uint256 required); // Insufficient balance for transfer. Needed `required` but only `available` available.
//Contract for individual project       
contract ProjectHandler{   
    address  immutable owner; //Variable to store contract owners address
    address  immutable teamSupervisor;    //Variable to store project supervisors wallet address
    uint256  balance;    //Variable to store total fund amount or balance of the project
    uint256  totalTransactions;   //Variable to store the total number of transactions 
    address[]  recipients;    //Array to store all the recipients wallet address
    mapping(address=>uint256)  recipientAddressToTotalAmount; //Array to store the total amount transferred to the recipients wallet till date
    //Constructor to initialise contract owner and project balance during the creation of contract to the project
    constructor(address _teamSupervisor){  
        owner = msg.sender;
        teamSupervisor = _teamSupervisor;
        balance = 0;
        totalTransactions = 0;
    }
    event FundDeposit(uint256 indexed _transactionId,uint256 _fundAmount);  //event that triggers during fund deposits
    event FundWithdrawal(uint256 indexed _transactionId,uint256 _withdrawAmount);  //event that triggers during fund withdrawals
    event NotTeamSupervisor(address indexed _notTeamSupervisor,uint256 _withdrawAmount);    //event that triggers due to failed transaction
    event NotOwner(address indexed _notOwner,uint256 _depositAmount);   //event that trigger due to failed fund deposits
    //Modifier to check if fund depositor is only owner(company admin)
    modifier onlyOwner(uint256 _depositAmount){
        //require(msg.sender==owner,"Depositor is not a Owner");
        if(msg.sender != owner)
        {
            totalTransactions += 1;
            emit NotOwner(msg.sender,_depositAmount);
            revert Unauthorized();
        }
        _;
    }
    //Modifier to check if withdrawal intiator is a team supervisor
    modifier onlyTeamSupervisor(address _recipientWallet,uint256 _withdrawAmount){
        if(msg.sender != teamSupervisor)
        {
            totalTransactions += 1;
            emit NotTeamSupervisor(msg.sender,_withdrawAmount);
            revert Unauthorized();
        }
        _;
    }
    //Function that allows the company(contract owner alone) to fund the project
    function Deposit() public payable onlyOwner(msg.value){
        balance +=  msg.value;
        totalTransactions += 1;
        emit FundDeposit(totalTransactions,msg.value);
    }
    //Function that allows the recipient to withdraw the specified amount and transfer to the specified wallet address !! Need to add a voting system
    function withdraw(address _recipientWallet,uint256 _withdrawAmount) public onlyTeamSupervisor(_recipientWallet,_withdrawAmount){
        if (_withdrawAmount >= balance){
            // Error call using named parameters. Equivalent to
            // Revert InsufficientBalance(balance[msg.sender], amount);
            totalTransactions += 1;
            revert InsufficientBalance({
                available: balance,
                required: _withdrawAmount
            });
        }
        (bool callSuccess,) = payable(_recipientWallet).call{value: _withdrawAmount}("");  //Transfers the specified amount of ethers to the recipient
        require(callSuccess,"Transfer to recipient Failed!");    //If transfer to recipient fails
        //Pushing, tracking recipients and updating balance details below
        balance -= _withdrawAmount;
        totalTransactions += 1;
        emit FundWithdrawal(totalTransactions,_withdrawAmount);
        //Pushing recipients address to array only if they are not already present
        if (recipientAddressToTotalAmount[_recipientWallet]==0)
        {
            recipients.push(_recipientWallet);
        }
        recipientAddressToTotalAmount[_recipientWallet] += _withdrawAmount;
    }
    //Function to be used when project goals are met to return 
    function projectCompleted() public onlyTeamSupervisor(owner,balance){
        (bool callSuccess, ) = payable(owner).call{value: address(this).balance}("");
        require(callSuccess,"Send Failed!");
        totalTransactions += 1;
        balance = 0;
    }
    //Feature function
    function getBalance() view public returns(uint256){
        return balance;
    }
    //Feature function
    function getTotalTransactions() view public returns(uint256){
        return totalTransactions;
    }
    //Feature fucntion
    function getReceipients() view public returns(address[] memory){
        return recipients;
    }
    //Feature fucntion
    function getReceipientsTotalAmountTransferred(address _recipientWallet) view public returns(uint256){
        return recipientAddressToTotalAmount[_recipientWallet];
    }
    receive() external payable{
        Deposit();
    }
    fallback() external payable{
        Deposit();
    }
} 
// Note :- Still need to add a voting system in the start of the withdraw function
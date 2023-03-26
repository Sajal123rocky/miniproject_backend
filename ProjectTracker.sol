//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
error Unauthorized();   //Mention of Error for notOwner(Unauthorized access)
error InsufficientBalance(uint256 available, uint256 required); // Insufficient balance for transfer. Needed `required` but only `available` available.
//Contract for individual project       
contract ProjectHandler{   
    address  immutable owner; //Variable to store contract owners address
    address  immutable financeValidator;    //Variable to store finance team bill validator wallet address
    uint256  totalFundsAllocated;   //Variable to store total funds allocated to the project till completion
    uint256  balance;    //Variable to store total fund amount or balance of the project
    uint256  totalTransactions;   //Variable to store the total number of transactions 
    address[]  recipients;    //Array to store all the recipients wallet address
    mapping(address=>uint256)  recipientAddressToTotalAmount; //Array to store the total amount transferred to the recipients wallet till date
    //Constructor to initialise contract owner and project balance during the creation of contract to the project
    constructor(address _financeValidator){  
        owner = msg.sender;
        financeValidator = _financeValidator;
        totalFundsAllocated = 0;
        balance = 0;
        totalTransactions = 0;
    }
    event FundDeposit(uint256 indexed _transactionId,uint256 _fundAmount);  //event that triggers during fund deposits
    event FundWithdrawal(uint256 indexed _transactionId,uint256 _withdrawAmount);  //event that triggers during fund withdrawals
    event ProjectCompleted(string indexed noteOfCompletion,uint256 _transactionId,uint256 _totalFundsAllocated,uint256 _withdrawalBalanceAmount); //event that triggers during project completion signaled by owner
    event NotFinanceValidator(address indexed _notFinanceValidator,address _recipientWallet,uint256 _withdrawAmount);    //event that triggers due to failed transaction
    event NotOwner(address indexed _notOwner);   //event that trigger due to failed fund deposits
    event NotFinanceTeam(address indexed _notFinanceTeam,uint256 _depositAmount);
    //Modifier to check if fund depositor is only owner(company admin)
    modifier onlyOwner(){
        //require(msg.sender==owner,"Depositor is not a Owner");
        if(msg.sender != owner)
        {
            totalTransactions += 1;
            emit NotOwner(msg.sender);
            revert Unauthorized();
        }
        _;
    }
    //Modifier to check if withdrawal intiator is a Finance team
    modifier onlyFinanceValidator(address _recipientWallet,uint256 _withdrawAmount){
        if(msg.sender != financeValidator)
        {
            totalTransactions += 1;
            emit NotFinanceValidator(msg.sender, _recipientWallet,_withdrawAmount);
            revert Unauthorized();
        }
        _;
    }
    //Mofifier to check if the depositor is by the Finance head 
    modifier onlyFinanceTeam(uint256 _depositAmount)
    {
        if(msg.sender != financeValidator)
        {
            totalTransactions += 1;
            emit NotFinanceTeam(msg.sender,_depositAmount);
            revert Unauthorized();
        }
        _;
    }
    //Function that allows the company(contract owner alone) to fund the project
    function Deposit() public payable onlyFinanceTeam(msg.value){
        totalFundsAllocated += msg.value;
        balance +=  msg.value;
        totalTransactions += 1;
        emit FundDeposit(totalTransactions,msg.value);
    }
    //Function that allows the recipient to withdraw the specified amount and transfer to the specified wallet address !!Need to add a vote system in 
    function withdraw(address payable _recipientWallet,uint256 _withdrawAmount) public onlyFinanceValidator(_recipientWallet,_withdrawAmount){
        if (_withdrawAmount > balance){
            // Error call using named parameters. Equivalent to
            // Revert InsufficientBalance(balance[msg.sender], amount);
            totalTransactions += 1;
            revert InsufficientBalance({
                available: balance,
                required: _withdrawAmount
            });
        }
        (bool callSuccess,) = _recipientWallet.call{value: _withdrawAmount}("");  //Transfers the specified amount of ethers to the recipient
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
    function projectCompleted() public onlyOwner(){
        (bool callSuccess, ) = payable(financeValidator).call{value: address(this).balance}("");
        require(callSuccess,"Send Failed!");
        balance = 0;
        totalTransactions += 1;
        emit ProjectCompleted("Project Completed",totalTransactions,totalFundsAllocated,balance);
    }
    //Feature function
    function getTotalFundsAllocated() view public returns(uint256)
    {
        return totalFundsAllocated;
    }
    //Feature function
    function getBalance() view public returns(uint256){
        return address(this).balance;
    }
    //Feature function
    function getTotalTransactions() view public returns(uint256){
        return totalTransactions;
    }
    //Feature function
    function getReceipients() view public returns(address[] memory){
        return recipients;
    }
    //Feature function
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
// Note :- Still need to add a voting system in the start of the withdraw function in the front end
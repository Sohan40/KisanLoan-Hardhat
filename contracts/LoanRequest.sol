// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import "hardhat/console.sol";


contract LoanRequest {

    struct Loan {
        bytes32 id;
        address farmer;
        address lender;
        uint256 amount;
        uint256 repaymentPeriod;
        bool approved;

    }

    uint256 public nonce ;
    constructor(){
        nonce = 0;
    }
    mapping (address => Loan[] ) farmerLoans;
    mapping (bytes32 => Loan) loanMapIdToLoanAddress ;
    mapping(address => Loan[]) lenderLoans;
    Loan[] public loanRequests;
     
     
     fallback() external payable {
     }
        function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
            // You can customize the implementation based on the interface you want to support
            return true; // Or specific logic to return true for certain interfaces
        }

        function decimals() external pure returns (uint8) {
            return 18; // A common default for ERC20 tokens
        }

        function symbol() external pure returns (string memory) {
            return "ETH"; // Replace with your token symbol
        }

    function requestLoan(uint256 _amount, uint256 _repaymentPeriod) public {

        bytes32 uniqueId = keccak256(abi.encodePacked(msg.sender, block.timestamp, nonce));

        Loan memory newLoan = Loan({
            id:uniqueId,
            farmer: msg.sender,
            lender: address(0),
            amount: _amount,
            repaymentPeriod: _repaymentPeriod,
            approved: false
        });

        farmerLoans[msg.sender].push(newLoan);
        loanRequests.push(newLoan);
        nonce++;
    }


    function getLoans() public view returns (Loan[] memory) {
      
        return loanRequests;
    }

    
    function disburseLoan(bytes32 _id, address payable _farmerAddress) public payable {
        require(msg.value > 0, "Must send Ether"); // Ensure some Ether is sent

        // Find the loan in farmerLoans
        bool loanFound = false;
        for (uint i = 0; i < farmerLoans[_farmerAddress].length; i++) {
            if (farmerLoans[_farmerAddress][i].id == _id) {
                loanFound = true; // Loan found
                (bool success, ) = _farmerAddress.call{value: msg.value}(""); // Send Ether
                require(success, "Transfer failed."); // Check if transfer was successful
                farmerLoans[_farmerAddress][i].lender = msg.sender; // Set lender
                break; // Exit loop once loan is found and processed
            }
        }

        console.log('came here');
        // Optionally, you can handle the case where the loan wasn't found
        require(loanFound, "Loan not found for farmer");

        // Update the loan request
        for (uint i = 0; i < loanRequests.length; i++) {
            if (loanRequests[i].id == _id) {
                loanRequests[i].lender = msg.sender; // Set lender
                lenderLoans[msg.sender].push(loanRequests[i]);
                break; // Exit loop once loan request is found and updated
            }
        }

        console.log('came here also');

    }

    function getLenderLoans(address _lender) public view returns(Loan [] memory){

        console.log(_lender,'has lended',lenderLoans[_lender].length);
        return lenderLoans[_lender];
    }

}

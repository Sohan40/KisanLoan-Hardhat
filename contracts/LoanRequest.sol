// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import "hardhat/console.sol";

contract LoanRequest {
    address public verifier;
    struct Loan {
        bytes32 id;
        address farmer;
        address lender;
        uint256 amount;
        uint256 repaymentPeriod;
        bool approved;
        string cid; // IPFS CID for loan-related documents
    }

    uint256 public nonce;

    constructor() {
        nonce = 0;
        verifier = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720;
    }

    mapping(address => Loan[]) farmerLoans;
    mapping(bytes32 => Loan) loanMapIdToLoanAddress;
    mapping(address => Loan[]) lenderLoans;
    Loan[] public loanRequests;

    fallback() external payable {}

    function supportsInterface(
        bytes4 interfaceID
    ) external pure returns (bool) {
        // You can customize the implementation based on the interface you want to support
        return true; // Or specific logic to return true for certain interfaces
    }

    function decimals() external pure returns (uint8) {
        return 18; // A common default for ERC20 tokens
    }

    function symbol() external pure returns (string memory) {
        return "ETH"; // Replace with your token symbol
    }


    function isVerifier(address _address) public view returns (bool) {
        return _address == verifier;
    }

    // Updated requestLoan function to accept and store CID
    function requestLoan(
        uint256 _amount,
        uint256 _repaymentPeriod,
        string memory _cid // New parameter to accept the IPFS CID
    ) public {
        bytes32 uniqueId = keccak256(
            abi.encodePacked(msg.sender, block.timestamp, nonce)
        );

        Loan memory newLoan = Loan({
            id: uniqueId,
            farmer: msg.sender,
            lender: address(0),
            amount: _amount,
            repaymentPeriod: _repaymentPeriod,
            approved: false,
            cid: _cid // Store the CID for this loan
        });

        loanMapIdToLoanAddress[uniqueId] = newLoan;
        farmerLoans[msg.sender].push(newLoan);
        loanRequests.push(newLoan);
        nonce++;
    }

    function getLoans() public view returns (Loan[] memory) {
        return loanRequests;
    }

    // Updated disburseLoan function to handle CID
    function disburseLoan(
        bytes32 _id,
        address payable _farmerAddress
    ) public payable {
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


        require(loanFound, "Loan not found for farmer");

        // Update the loan request
        for (uint i = 0; i < loanRequests.length; i++) {
            if (loanRequests[i].id == _id) {
                loanRequests[i].lender = msg.sender; // Set lender
                lenderLoans[msg.sender].push(loanRequests[i]);
                break; // Exit loop once loan request is found and updated
            }
        }

        console.log("came here also");
    }

    function getLenderLoans(
        address _lender
    ) public view returns (Loan[] memory) {
        console.log(_lender, "has lended", lenderLoans[_lender].length);
        return lenderLoans[_lender];
    }

    // Updated approveLoan to handle CID (CID remains unchanged, but it’s part of the loan struct)
    function approveLoan(bytes32 _loanID) public {
        // Check if the loan exists
        Loan storage loanToApprove = loanMapIdToLoanAddress[_loanID];
        require(loanToApprove.farmer != address(0), "Loan does not exist");

        // 1. Update in loanMapIdToLoanAddress
        loanToApprove.approved = true;

        // 2. Update in farmerLoans
        Loan[] storage farmerLoansArray = farmerLoans[loanToApprove.farmer];
        for (uint256 i = 0; i < farmerLoansArray.length; i++) {
            if (farmerLoansArray[i].id == _loanID) {
                farmerLoansArray[i].approved = true;
                break;
            }
        }

        // 3. Update in loanRequests
        for (uint256 i = 0; i < loanRequests.length; i++) {
            if (loanRequests[i].id == _loanID) {
                loanRequests[i].approved = true;
                break;
            }
        }
    }

    // Updated deleteLoan to handle CID (CID remains unchanged)
    function deleteLoan(bytes32 _loanID) public {
        // Check if the loan exists
        Loan memory loanToDelete = loanMapIdToLoanAddress[_loanID];
        require(loanToDelete.farmer != address(0), "Loan does not exist");

        // 1. Remove from farmerLoans
        Loan[] storage farmerLoansArray = farmerLoans[loanToDelete.farmer];
        for (uint256 i = 0; i < farmerLoansArray.length; i++) {
            if (farmerLoansArray[i].id == _loanID) {
                farmerLoansArray[i] = farmerLoansArray[farmerLoansArray.length - 1]; // Move the last element to the current index
                farmerLoansArray.pop(); // Remove the last element
                break;
            }
        }

        // 2. Remove from loanMapIdToLoanAddress
        delete loanMapIdToLoanAddress[_loanID];

        // 3. Remove from loanRequests
        for (uint256 i = 0; i < loanRequests.length; i++) {
            if (loanRequests[i].id == _loanID) {
                loanRequests[i] = loanRequests[loanRequests.length - 1]; // Move the last element to the current index
                loanRequests.pop(); // Remove the last element
                break;
            }
        }
    }
}

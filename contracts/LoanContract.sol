// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;
import "hardhat/console.sol";

contract LoanContract {
    struct Loan {
        uint256 id;
        address lender;
        uint256 amount;
        uint256 interestRate; // interest rate in percentage
        uint256 term; // loan term in months
        string description;
        bool isActive; // indicates if the loan is active
    }

    // State variables
    mapping(uint256 => Loan) public loans; // Maps loan ID to Loan struct
    mapping(address => Loan[]) public lenderLoans; // Maps lender address to an array of Loan structs
    uint256 public loanCount; // Tracks the total number of loans

    // Events
    event LoanAdded(
        uint256 id,
        address indexed lender,
        uint256 amount,
        uint256 interestRate,
        uint256 term,
        string description
    );

    // Function to add a new loan
    function addLoan(
        uint256 _amount,
        uint256 _interestRate,
        uint256 _term,
        string memory _description
    ) public {
        require(_amount > 0, "Loan amount must be greater than 0");
        require(_interestRate > 0, "Interest rate must be greater than 0");
        require(_term > 0, "Loan term must be greater than 0");

        loanCount++;
        Loan memory newLoan = Loan({
            id: 1,
            lender: msg.sender,
            amount: _amount,
            interestRate: _interestRate,
            term: _term,
            description: _description,
            isActive: true
        });

        loans[loanCount] = newLoan;

        // Map the loan struct to the lender's address
        lenderLoans[msg.sender].push(newLoan);

        
        emit LoanAdded(loanCount, msg.sender, _amount, _interestRate, _term, _description);
    }



    // Function to get all loans created by a specific lender
    function getLenderLoans() public view returns (Loan[] memory) {
        console.log(msg.sender);
        return lenderLoans[msg.sender];
    }

    // Function to deactivate a loan (optional)
}

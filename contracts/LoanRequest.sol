// pragma solidity ^0.8.26;
// pragma abicoder v2;
// import "hardhat/console.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// contract LoanRequest {
//     address public verifier;
//     struct Loan {
//         bytes32 id;
//         address farmer;
//         address lender;
//         uint256 amount;
//         uint256 repaymentPeriod;
//         // bool approved;
//         string cid; // IPFS CID for loan-related documents
//         // bool sanctioned;
//         uint256 emi;
//         uint256 emiPaidCount;
//         // bool rejected;
//         address nftContract;
//         uint256 tokenId;
//         uint256 lastPaymentDate;
//         Status status;
//     }

//     struct Status {
//         bool approved;
//         bool sanctioned;
//         bool rejected;
//         bool inDefault;
//     }

//     uint256 public nonce;
//     uint256 public constant GRACE_PERIOD = 15 days;

//     constructor() {
//         nonce = 0;
//         verifier = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720;
//     }

//     mapping(address => Loan[]) farmerLoans;
//     mapping(bytes32 => Loan) loanMapIdToLoanAddress;
//     mapping(address => Loan[]) lenderLoans;
//     Loan[] public loanRequests;



//     function isVerifier(address _address) public view returns (bool) {
//         return _address == verifier;
//     }

//     // Updated requestLoan function to accept and store CID
//     function requestLoan(
//         uint256 _amount,
//         uint256 _repaymentPeriod,
//         string memory _cid, // New parameter to accept the IPFS CID
//         address _nftContract,
//         uint256 _tokenId
//     ) public {

//         require(IERC721(_nftContract).ownerOf(_tokenId) == msg.sender, "Not NFT owner");
        
//         // Transfer NFT to escrow
//         IERC721(_nftContract).transferFrom(msg.sender, address(this), _tokenId);

//         bytes32 uniqueId = keccak256(
//             abi.encodePacked(msg.sender, block.timestamp, nonce)
//         );

//         Loan memory newLoan = Loan({
//             id: uniqueId,
//             farmer: msg.sender,
//             lender: address(0),
//             amount: _amount,
//             repaymentPeriod: _repaymentPeriod,
//             approved: false,
//             sanctioned: false,
//             cid: _cid ,// Store the CID for this loan
//             emi : uint(0),
//             emiPaidCount : uint(0),
//             rejected: false,
//             nftContract: _nftContract,
//             tokenId: _tokenId,
//             lastPaymentDate: 0,
//             inDefault: false
//         });

//         loanMapIdToLoanAddress[uniqueId] = newLoan;
//         farmerLoans[msg.sender].push(newLoan);
//         loanRequests.push(newLoan);
//         nonce++;
//     }

//     function getLoans() public view returns (Loan[] memory) {
//         return loanRequests;
//     }

//     function getLoanWithId(bytes32 _loanId) public view returns (Loan memory){
//         return loanMapIdToLoanAddress[_loanId];
//     }

//     function getFarmerLoans() public view returns (Loan [] memory){
//         console.log(msg.sender);
//         return farmerLoans[msg.sender];
//     }

//     function calculateEMI(uint256 principal, uint256 months) internal pure returns (uint256) {
//         uint256 monthlyInterestRate = (3 * 1e18) / 12 / 100;
//         uint256 factor = 1e18;
        
//         for (uint256 j = 0; j < months; j++) {
//             factor = (factor * (1e18 + monthlyInterestRate)) / 1e18;
//         }
        
//         uint256 numerator = (principal * monthlyInterestRate * factor) / 1e18;
//         uint256 denominator = factor - 1e18;
//         return (numerator + denominator - 1) / denominator;
//     }

//     function disburseLoan(
//         bytes32 _id,
//         address payable _farmerAddress
//     ) public payable {
//         require(msg.value > 0, "Must send Ether");
        
//         uint i;
//         uint256 emiamount = 0;
//         for ( i = 0; i < farmerLoans[_farmerAddress].length; i++) {
//             if (farmerLoans[_farmerAddress][i].id == _id) {
                

//                 (bool success, ) = _farmerAddress.call{value: msg.value}("");
//                 require(success, "Transfer failed.");
//                 farmerLoans[_farmerAddress][i].lender = msg.sender;
//                 farmerLoans[_farmerAddress][i].sanctioned = true;

//                  // 3% annual interest
//                  emiamount = calculateEMI(farmerLoans[_farmerAddress][i].amount, farmerLoans[_farmerAddress][i].repaymentPeriod);

//                 farmerLoans[_farmerAddress][i].emi = emiamount;
//                 break;
//             }
//         }

//         require(i!=farmerLoans[_farmerAddress].length, "Loan not found for farmer");

//         _updateLoanState(_id,emiamount);
//     }

//     function _updateLoanState(bytes32 _id, uint256 emiamount) private {
//         Loan storage loan = loanMapIdToLoanAddress[_id];
//         require(loan.farmer != address(0), "Loan does not exist");
        
//         loan.lender = msg.sender;
//         loan.emi = emiamount;
//         loan.sanctioned = true;

//         for (uint i = 0; i < loanRequests.length; i++) {
//             if (loanRequests[i].id == _id) {
//                 loanRequests[i].lender = msg.sender;
//                 loanRequests[i].emi = emiamount;
//                 loanRequests[i].sanctioned = true;
//                 lenderLoans[msg.sender].push(loanRequests[i]);
//                 break;
//             }
//         }

//         Loan storage loanToApprove = loanMapIdToLoanAddress[_id];
//         require(loanToApprove.farmer != address(0), "Loan does not exist");
//         loanToApprove.lender = msg.sender;
//         loanToApprove.emi = emiamount;
//         loanToApprove.sanctioned = true;
//     }

//     function getLenderLoans(
//         address _lender
//     ) public view returns (Loan[] memory) {
//         console.log(_lender, "has lended", lenderLoans[_lender].length);
//         return lenderLoans[_lender];
//     }

//     // Updated approveLoan to handle CID (CID remains unchanged, but it’s part of the loan struct)
//     function approveLoan(bytes32 _loanID) public {
//         // Check if the loan exists
//         Loan storage loanToApprove = loanMapIdToLoanAddress[_loanID];
//         require(loanToApprove.farmer != address(0), "Loan does not exist");

//         // 1. Update in loanMapIdToLoanAddress
//         loanToApprove.approved = true;

//         // 2. Update in farmerLoans
//         Loan[] storage farmerLoansArray = farmerLoans[loanToApprove.farmer];
//         for (uint256 i = 0; i < farmerLoansArray.length; i++) {
//             if (farmerLoansArray[i].id == _loanID) {
//                 farmerLoansArray[i].approved = true;
//                 break;
//             }
//         }

//         // 3. Update in loanRequests
//         for (uint256 i = 0; i < loanRequests.length; i++) {
//             if (loanRequests[i].id == _loanID) {
//                 loanRequests[i].approved = true;
//                 break;
//             }
//         }
//     }

//     // Updated deleteLoan to handle CID (CID remains unchanged)
//     function deleteLoan(bytes32 _loanID) public {
//         // Check if the loan exists
//         Loan memory loanToDelete = loanMapIdToLoanAddress[_loanID];
//         require(loanToDelete.farmer != address(0), "Loan does not exist");

//         // 1. Remove from farmerLoans
//         Loan[] storage farmerLoansArray = farmerLoans[loanToDelete.farmer];
//         for (uint256 i = 0; i < farmerLoansArray.length; i++) {
//             if (farmerLoansArray[i].id == _loanID) {
//                 farmerLoansArray[i] = farmerLoansArray[farmerLoansArray.length - 1]; // Move the last element to the current index
//                 farmerLoansArray.pop(); // Remove the last element
//                 break;
//             }
//         }

//         // 2. Remove from loanMapIdToLoanAddress
//         delete loanMapIdToLoanAddress[_loanID];

//         // 3. Remove from loanRequests
//         for (uint256 i = 0; i < loanRequests.length; i++) {
//             if (loanRequests[i].id == _loanID) {
//                 loanRequests[i] = loanRequests[loanRequests.length - 1]; // Move the last element to the current index
//                 loanRequests.pop(); // Remove the last element
//                 break;
//             }
//         }
//     }

//     function rejectLoan(bytes32 _loanID) public {
//         // Check if the loan exists
//          Loan storage loanToApprove = loanMapIdToLoanAddress[_loanID];
//         require(loanToApprove.farmer != address(0), "Loan does not exist");

//         // 1. Update in loanMapIdToLoanAddress
//         loanToApprove.rejected = true;

//         // 2. Update in farmerLoans
//         Loan[] storage farmerLoansArray = farmerLoans[loanToApprove.farmer];
//         for (uint256 i = 0; i < farmerLoansArray.length; i++) {
//             if (farmerLoansArray[i].id == _loanID) {
//                 farmerLoansArray[i].rejected = true;
//                 break;
//             }
//         }

//         // 3. Update in loanRequests
//         for (uint256 i = 0; i < loanRequests.length; i++) {
//             if (loanRequests[i].id == _loanID) {
//                 loanRequests[i].rejected = true;
//                 break;
//             }
//         }
//     }

//     function payEmi(bytes32 loanId,address payable _lenderAddress) public payable {

//         Loan storage loan = loanMapIdToLoanAddress[loanId];
//         console.log(loan.farmer);
//         loan.lastPaymentDate = block.timestamp;
//         // Validate loan existence
//         require(loan.farmer != address(0), "Loan does not exist");
//         require(loan.farmer == msg.sender, "Only the farmer can pay the EMI");
//         require(loan.sanctioned, "Loan is not sanctioned");
//         require(loan.approved, "Loan is not approved");
        
//         (bool success, ) = _lenderAddress.call{value: msg.value}("");
//         require(success, "EMI transfer to lender failed");

//         // Update emiPaidCount in the loanMapIdToLoanAddress
//         loan.emiPaidCount++;

//          if (loan.emiPaidCount >= loan.repaymentPeriod) {
//             IERC721(loan.nftContract).transferFrom(address(this), loan.farmer, loan.tokenId);
//         }

//         // Update emiPaidCount in farmerLoans mapping
//         Loan[] storage farmerLoansArray = farmerLoans[loan.farmer];
//         for (uint256 i = 0; i < farmerLoansArray.length; i++) {
//             if (farmerLoansArray[i].id == loanId) {
//                 farmerLoansArray[i].emiPaidCount = loan.emiPaidCount;
//                 break;
//             }
//         }

//         // Update emiPaidCount in lenderLoans mapping
//         Loan[] storage lenderLoansArray = lenderLoans[loan.lender];
//         for (uint256 i = 0; i < lenderLoansArray.length; i++) {
//             if (lenderLoansArray[i].id == loanId) {
//                 lenderLoansArray[i].emiPaidCount = loan.emiPaidCount;
//                 break;
//             }
//         }

//         // Update emiPaidCount in loanRequests array
//         for (uint256 i = 0; i < loanRequests.length; i++) {
//             if (loanRequests[i].id == loanId) {
//                 loanRequests[i].emiPaidCount = loan.emiPaidCount;
//                 break;
//             }
//         }
//     }

//     function checkDefault(bytes32 loanId) public {
//         Loan storage loan = loanMapIdToLoanAddress[loanId];
//         require(loan.sanctioned, "Loan not active");
        
//         if (block.timestamp > loan.lastPaymentDate + 30 days && !loan.inDefault) {
//             loan.inDefault = true;
//         }
//     }

//     function liquidateCollateral(bytes32 loanId) public {
//         Loan storage loan = loanMapIdToLoanAddress[loanId];
//         require(loan.inDefault, "Loan not in default");
//         require(block.timestamp > loan.lastPaymentDate + 30 days + GRACE_PERIOD, "Grace period active");
        
//         IERC721(loan.nftContract).transferFrom(address(this), loan.lender, loan.tokenId);
//     }


// }
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
pragma abicoder v2;
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract LoanRequest {
    address public verifier;
    
    struct Status {
        bool approved;
        bool sanctioned;
        bool rejected;
        bool inDefault;
        bool closed;
        bool liquidated;
    }

    struct Loan {
        bytes32 id;
        address farmer;
        address lender;
        uint256 amount;
        uint256 repaymentPeriod;
        string cid;
        uint256 emi;
        uint256 emiPaidCount;
        address nftContract;
        uint256 tokenId;
        uint256 lastPaymentDate;
        Status status;
    }

    uint256 public nonce;
    uint256 public constant GRACE_PERIOD = 1 ;

    constructor() {
        nonce = 0;
        verifier = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720;
    }

    mapping(address => Loan[]) farmerLoans;
    mapping(bytes32 => Loan) loanMapIdToLoanAddress;
    mapping(address => Loan[]) lenderLoans;
    Loan[] public loanRequests;

    function isVerifier(address _address) public view returns (bool) {
        return _address == verifier;
    }

    function requestLoan(
        uint256 _amount,
        uint256 _repaymentPeriod,
        string memory _cid,
        address _nftContract,
        uint256 _tokenId

    ) public {
        require(IERC721(_nftContract).ownerOf(_tokenId) == msg.sender, "Not NFT owner");
        IERC721(_nftContract).transferFrom(msg.sender, address(this), _tokenId);

        bytes32 uniqueId = keccak256(abi.encodePacked(msg.sender, block.timestamp, nonce));
        
        Loan memory newLoan = Loan({
            id: uniqueId,
            farmer: msg.sender,
            lender: address(0),
            amount: _amount,
            repaymentPeriod: _repaymentPeriod,
            cid: _cid,
            emi: 0,
            emiPaidCount: 0,
            nftContract: _nftContract,
            tokenId: _tokenId,
            lastPaymentDate: 0,
            status: Status(false, false, false, false,false,false)
        });

        loanMapIdToLoanAddress[uniqueId] = newLoan;
        farmerLoans[msg.sender].push(newLoan);
        loanRequests.push(newLoan);
        nonce++;
    }

    function getLoans() public view returns (Loan[] memory) {
        return loanRequests;
    }

    function getLoanWithId(bytes32 _loanId) public view returns (Loan memory) {
        return loanMapIdToLoanAddress[_loanId];
    }

    function getFarmerLoans() public view returns (Loan[] memory) {
        return farmerLoans[msg.sender];
    }

    function calculateEMI(uint256 principal, uint256 months) internal pure returns (uint256) {
        uint256 monthlyInterestRate = (3 * 1e18) / 12 / 100;
        uint256 factor = 1e18;
        
        for (uint256 j = 0; j < months; j++) {
            factor = (factor * (1e18 + monthlyInterestRate)) / 1e18;
        }
        
        uint256 numerator = (principal * monthlyInterestRate * factor) / 1e18;
        uint256 denominator = factor - 1e18;
        return (numerator + denominator - 1) / denominator;
    }

    function disburseLoan(bytes32 _id, address payable _farmerAddress) public payable {
        require(msg.value > 0, "Must send Ether");
        
        bool found;
        uint256 emiAmount;
        for (uint i = 0; i < farmerLoans[_farmerAddress].length; i++) {
            if (farmerLoans[_farmerAddress][i].id == _id) {
                (bool success, ) = _farmerAddress.call{value: msg.value}("");
                require(success, "Transfer failed");
                
                emiAmount = calculateEMI(
                    farmerLoans[_farmerAddress][i].amount,
                    farmerLoans[_farmerAddress][i].repaymentPeriod
                );
                
                farmerLoans[_farmerAddress][i].lender = msg.sender;
                farmerLoans[_farmerAddress][i].status.sanctioned = true;
                farmerLoans[_farmerAddress][i].emi = emiAmount;
                found = true;
                break;
            }
        }
        require(found, "Loan not found");
        _updateLoanState(_id, emiAmount);
    }

    function _updateLoanState(bytes32 _id, uint256 emiAmount) private {
        Loan storage loan = loanMapIdToLoanAddress[_id];
        require(loan.farmer != address(0), "Loan does not exist");
        
        loan.lender = msg.sender;
        loan.emi = emiAmount;
        loan.status.sanctioned = true;

        for (uint i = 0; i < loanRequests.length; i++) {
            if (loanRequests[i].id == _id) {
                loanRequests[i].lender = msg.sender;
                loanRequests[i].emi = emiAmount;
                loanRequests[i].status.sanctioned = true;
                lenderLoans[msg.sender].push(loanRequests[i]);
                break;
            }
        }
    }

    function getLenderLoans(address _lender) public view returns (Loan[] memory) {
        return lenderLoans[_lender];
    }

    function approveLoan(bytes32 _loanID) public {
        Loan storage loan = loanMapIdToLoanAddress[_loanID];
        require(loan.farmer != address(0), "Loan does not exist");
        loan.status.approved = true;

        Loan[] storage farmerLoansArray = farmerLoans[loan.farmer];
        for (uint256 i = 0; i < farmerLoansArray.length; i++) {
            if (farmerLoansArray[i].id == _loanID) {
                farmerLoansArray[i].status.approved = true;
                break;
            }
        }

        for (uint256 i = 0; i < loanRequests.length; i++) {
            if (loanRequests[i].id == _loanID) {
                loanRequests[i].status.approved = true;
                break;
            }
        }
    }

    function deleteLoan(bytes32 _loanID) public {
        Loan memory loan = loanMapIdToLoanAddress[_loanID];
        require(loan.farmer != address(0), "Loan does not exist");

        Loan[] storage farmerLoansArray = farmerLoans[loan.farmer];
        for (uint256 i = 0; i < farmerLoansArray.length; i++) {
            if (farmerLoansArray[i].id == _loanID) {
                farmerLoansArray[i] = farmerLoansArray[farmerLoansArray.length - 1];
                farmerLoansArray.pop();
                break;
            }
        }

        delete loanMapIdToLoanAddress[_loanID];
        for (uint256 i = 0; i < loanRequests.length; i++) {
            if (loanRequests[i].id == _loanID) {
                loanRequests[i] = loanRequests[loanRequests.length - 1];
                loanRequests.pop();
                break;
            }
        }
    }

    function rejectLoan(bytes32 _loanID) public {
        Loan storage loan = loanMapIdToLoanAddress[_loanID];
        require(loan.farmer != address(0), "Loan does not exist");
        loan.status.rejected = true;

        Loan[] storage farmerLoansArray = farmerLoans[loan.farmer];
        for (uint256 i = 0; i < farmerLoansArray.length; i++) {
            if (farmerLoansArray[i].id == _loanID) {
                farmerLoansArray[i].status.rejected = true;
                break;
            }
        }

        for (uint256 i = 0; i < loanRequests.length; i++) {
            if (loanRequests[i].id == _loanID) {
                loanRequests[i].status.rejected = true;
                break;
            }
        }
    }

    function payEmi(bytes32 loanId, address payable _lenderAddress) public payable {
        Loan storage loan = loanMapIdToLoanAddress[loanId];
        loan.lastPaymentDate = block.timestamp;
        
        require(loan.farmer != address(0), "Loan does not exist");
        require(loan.farmer == msg.sender, "Only farmer can pay");
        require(loan.status.sanctioned, "Loan not sanctioned");
        require(loan.status.approved, "Loan not approved");
        
        (bool success, ) = _lenderAddress.call{value: msg.value}("");
        require(success, "EMI transfer failed");

        loan.emiPaidCount++;
        if (loan.emiPaidCount >= loan.repaymentPeriod) {
            IERC721(loan.nftContract).transferFrom(address(this), loan.farmer, loan.tokenId);
        }

        _updateLoanCounters(loanId, loan.emiPaidCount);
    }

    function _updateLoanCounters(bytes32 loanId, uint256 newCount) private {
        Loan[] storage farmerLoansArray = farmerLoans[msg.sender];
        for (uint256 i = 0; i < farmerLoansArray.length; i++) {
            if (farmerLoansArray[i].id == loanId) {
                farmerLoansArray[i].emiPaidCount = newCount;
                break;
            }
        }

        Loan storage loan = loanMapIdToLoanAddress[loanId];
        Loan[] storage lenderLoansArray = lenderLoans[loan.lender];
        for (uint256 i = 0; i < lenderLoansArray.length; i++) {
            if (lenderLoansArray[i].id == loanId) {
                lenderLoansArray[i].emiPaidCount = newCount;
                break;
            }
        }

        for (uint256 i = 0; i < loanRequests.length; i++) {
            if (loanRequests[i].id == loanId) {
                loanRequests[i].emiPaidCount = newCount;
                break;
            }
        }
    }

    function checkDefault(bytes32 loanId) public {
        Loan storage loan = loanMapIdToLoanAddress[loanId];
        require(loan.status.sanctioned, "Loan not active");
        
        if (block.timestamp > loan.lastPaymentDate + 1 minutes && !loan.status.inDefault) {
            loan.status.inDefault = true;
        }
    }

    function liquidateCollateral(bytes32 loanId) public {
        Loan storage loan = loanMapIdToLoanAddress[loanId];
        require(loan.status.inDefault, "Loan not in default");
        require(block.timestamp > loan.lastPaymentDate + 1 minutes + GRACE_PERIOD, "Grace period active");
        
        IERC721(loan.nftContract).transferFrom(address(this), loan.lender, loan.tokenId);


        require(loan.farmer != address(0), "Loan does not exist");
        loan.status.liquidated = true;
        loan.status.closed = true;
        Loan[] storage farmerLoansArray = farmerLoans[loan.farmer];
        for (uint256 i = 0; i < farmerLoansArray.length; i++) {
            if (farmerLoansArray[i].id == loanId) {
                loan.status.liquidated = true;
                loan.status.closed = true;
                break;
            }
        }

        for (uint256 i = 0; i < loanRequests.length; i++) {
            if (loanRequests[i].id == loanId) {
                loan.status.liquidated = true;
                loan.status.closed = true;
                break;
            }
        }
    }
}
// // // SPDX-License-Identifier: Apache-2.0
// pragma solidity ^0.8.7;
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// interface IMYNTIST {
//     function mintAmountForNftAA(address _to, uint256 _amount) external;
// }

// interface IMYNTIST_NFT {
//     function balanceOf(address user) external view returns (uint256);
// }

// interface IMYNTISTB_1155 {
//     function getTokenIds() external view returns (uint256[] memory);

//     function balanceOf(address account, uint256 id)
//         external
//         view
//         returns (uint256);
// }

// interface IMYNTISTE_1155 {
//     function getTokenIds() external view returns (uint256[] memory);

//     function balanceOf(address account, uint256 id)
//         external
//         view
//         returns (uint256);
// }

// contract NFTAA {
//     address nftContractAddress;
//     uint256 internal constant LAUNCH_TIME = 1666175824;
//     uint256 internal constant totalSupply = 750000000 * 10**8;
//     uint256 internal constant perDaySupply = totalSupply / 365;
//     address internal owner;
//     IMYNTIST public tokenContarct;
//     IMYNTIST_NFT public nftContract;
//     IMYNTISTB_1155 public collectionContract;
//     IMYNTISTE_1155 public collectionContract2;

//     struct recordsStruct {
//         uint256 userTotalBalance;
//         bool isClaim;
//     }
//     mapping(uint256 => mapping(address => recordsStruct)) public userRecord;
//     mapping(uint256 => uint256) public totalBalancePerDay;

//     modifier onlyOwner() {
//         require(msg.sender == owner);
//         _;
//     }

//     constructor(
//         address myntistTokenAddress,
//         address myntistNftAddress,
//         address myntist1155BAddress,
//         address myntist1155EAddress
//     ) {
//         nftContract = IMYNTIST_NFT(myntistNftAddress);
//         tokenContarct = IMYNTIST(myntistTokenAddress);
//         collectionContract = IMYNTISTB_1155(myntist1155BAddress);
//         collectionContract2 = IMYNTISTE_1155(myntist1155EAddress);
//     }

//     function getUserNFTBalance(address userAddress)
//         external
//         view
//         returns (uint256)
//     {
//         return nftContract.balanceOf(userAddress);
//     }

//     function get1155BUserBalance(address userAddress)
//         public
//         view
//         returns (uint256 userBalance)
//     {
//         uint256[] memory ids = collectionContract.getTokenIds();
//         for (uint256 i = 0; i < ids.length; i++) {
//             uint256 balance = collectionContract.balanceOf(userAddress, ids[i]);
//             userBalance = userBalance + balance;
//         }
//         return userBalance;
//     }

//     function get1155EUserBalance(address userAddress)
//         public
//         view
//         returns (uint256 userBalance)
//     {
//         uint256[] memory ids = collectionContract2.getTokenIds();
//         for (uint256 i = 0; i < ids.length; i++) {
//             uint256 balance = collectionContract2.balanceOf(
//                 userAddress,
//                 ids[i]
//             );
//             userBalance = userBalance + balance;
//         }
//         return userBalance;
//     }

//     function _currentDay() internal view returns (uint256) {
//         return (block.timestamp - LAUNCH_TIME) / 300;
//     }

//     function enterLobby(address user) external {
//         uint256 enterDay = _currentDay();
//         uint256 nftBalance = nftContract.balanceOf(user);
//         uint256 balance1155B = get1155BUserBalance(user);
//         uint256 balance1155E = get1155EUserBalance(user);
//         uint256 totalBalance = nftBalance + balance1155B + balance1155E;
//         recordsStruct storage qRef = userRecord[enterDay][user];
//         require(
//             qRef.userTotalBalance == 0 && totalBalance > 0,
//             "Already Added for current day"
//         );
//         qRef.userTotalBalance = totalBalance;
//         qRef.isClaim = false;
//         totalBalancePerDay[enterDay] += totalBalance;
//     }

//     function claimTokens(uint256 day, address user) external {
//         uint256 currentDay = _currentDay();
//         require(day == currentDay - 1 && day != 0, "Not claim Day");
//         recordsStruct storage qRef = userRecord[day][user];
//         require(qRef.userTotalBalance > 0, "Record Not Found");
//         require(qRef.isClaim == false, "Already Claimed");
//         uint256 userShare = (perDaySupply * qRef.userTotalBalance) /
//             totalBalancePerDay[day];
//         tokenContarct.mintAmountForNftAA(msg.sender, userShare);
//         qRef.isClaim = true;
//     }

//     function resetContractAddresses(
//         address myntistTokenAddress,
//         address myntistNftAddress,
//         address myntist1155BAddress,
//         address myntist1155EAddress
//     ) external onlyOwner{
//         nftContract = IMYNTIST_NFT(myntistNftAddress);
//         tokenContarct = IMYNTIST(myntistTokenAddress);
//         collectionContract = IMYNTISTB_1155(myntist1155BAddress);
//         collectionContract2 = IMYNTISTE_1155(myntist1155EAddress);
//     }
// }

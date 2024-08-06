// contracts/MiniAdoptionAmplifier.sol
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IPTP {
    function mintAmount(address _to, uint256 _amount) external;
}

/**
 * @title MiniAdoptionAmpifier
 */

contract miniAdoptionAmpifier is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    // Free Claimers Pool struct
    struct FreeClaimers {
        // Address of the free claimer
        address user;
        // Stores the current year
        uint256 year;
    }
    // Reward pool points Depositers struct
    struct Depositers {
        // Address of the point depositer
        address user;
        // Amount of points
        uint256 amount;
        // Stores the current year
        uint256 year;
    }
    // Signature struct
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    mapping(bytes32 => bool) public executed;

    // ***********  Config  ***********
    // Set Start Date
    uint public startDate;
    IPTP public ptpToken; // PTP Token Instance
    uint public DAY = 86400; // In Seconds 86400
    uint public YEAR = 31536000; // Seconds in Year
    uint public DECIMAL = 18; //
    // ********************************

    // Stores the reward amount of 63 years
    uint256[] public yearsReward;
    // Mappings for Free claim pool
    mapping(uint256 => FreeClaimers[]) public todayFreeClaimers;
    mapping(uint256 => mapping(address => bool)) public claimStatusFreePool;

    // Mappings for Rewards based on points pool
    // mapping(address => uint256) public pointsBalance;
    mapping(uint256 => Depositers[]) public todayDepositers;
    mapping(uint256 => mapping(address => bool)) public claimStatusRewardPool;

    // ********** Events **********
    /**
     * @notice Emmits whenever the new user added to freeClaim pool.
     */
    event EnteredForFreeClaim(uint indexed _day, address indexed _user);
    /**
     * @notice Emmits when the user claims the previous day free reward.
     */
    event ClaimedFreePTP(
        uint indexed _day,
        uint indexed _rewardAmount,
        address indexed _user
    );
    /**
     * @notice Emmits whenever the user deposits there points into reward pool.
     */
    event pointsDeposited(
        uint indexed _day,
        uint indexed _points,
        address indexed _user,
        uint nonce
    );
    /**
     * @notice Emmits when the user claims the previous day reward of deposited points.
     */
    event RewardClaimed(
        uint indexed _day,
        uint indexed _ptpAmount,
        address indexed _user
    );
    /**
     * @notice Emmits when the user claims the points eraned from gamification.
     */
    event PointsEarned(
        address indexed _user,
        uint indexed _amount,
        uint indexed _nonce
    );

    /**
     * @dev Creates a miniAA contract.
     * @param _start Start date of the pools in Seconds
     * @param _ptp Address of the PTP token Contract
     */
    constructor(uint _start, address _ptp) {
        startDate = _start;
        ptpToken = IPTP(_ptp);
        // Init the reward amount for next 63 years from start date
        setYearsReward();
    }

    receive() external payable {}

    fallback() external payable {}

    /**
     * @notice OnlyOwner Function
     * @dev set the start date in Seconds.
     * @param _startDate Start date of the pools in Seconds
     */
    function setStartDate(uint _startDate) public onlyOwner {
        startDate = _startDate;
    }

    /**
     * @notice OnlyOwner Function
     * @dev Set the day Duration in Seconds Default 86400.
     * @param _day no of seconds in day
     */
    function setDay(uint _day) public onlyOwner {
        DAY = _day;
    }

    /**
     * @notice OnlyOwner Function
     * @dev Set the year Duration in Seconds Default 31558995.
     * @param _year no of seconds in year.
     */
    function setYear(uint _year) public onlyOwner {
        YEAR = _year;
    }

    /**
     * @notice Find and retuns the current year from start date
     */
    function findYear() public view returns (uint256) {
        require(block.timestamp >= startDate, "Not Start Yet!");
        uint year = block.timestamp.sub(startDate);
        year = year.div(YEAR);
        return year;
    }

    /**
     * @notice Find and retuns the current day from start date
     */
    function findDay() public view returns (uint256) {
        require(block.timestamp >= startDate, "Not Start Yet!");
        uint256 day = block.timestamp.sub(startDate);
        return day.div(DAY);
    }

    /**
     * @notice Return the number of free claimers on the given day
     * @param _day enter the day you want no of free claimers
     */
    function countFreeClaimers(uint _day) public view returns (uint) {
        return todayFreeClaimers[_day].length;
    }

    //   **************Optional Functions**************

    /**
     * @notice Sets and init the Reward for next 63 years
     * @dev Private Function (Only called on deployement)
     */
    function setYearsReward() private {
        uint256 ptpAmount = 2000000000;
        uint256 ptpAvailable = 0;
        for (uint256 i = 0; i < 63; i++) {
            if (i == 0) {
                ptpAvailable = ptpAmount;
            } else if (i >= 1 && i <= 2) {
                ptpAvailable = ptpAmount.div(2);
            } else if (i >= 3 && i <= 6) {
                ptpAvailable = ptpAmount.div(4);
            } else if (i >= 7 && i <= 14) {
                ptpAvailable = ptpAmount.div(8);
            } else if (i >= 15 && i <= 30) {
                ptpAvailable = ptpAmount.div(16);
            } else if (i >= 31 && i <= 62) {
                ptpAvailable = ptpAmount.div(32);
            }
            yearsReward.push(ptpAvailable);
        }
    }

    /**
     * @notice Returns the lenght of years reward
     * @dev Optional function
     */
    function getYearsLength() public view returns (uint) {
        return yearsReward.length;
    }

    /**
     * @notice Returns the yearReward Array
     * @dev Optional function
     */
    function getAllYearsReward() public view returns (uint256[] memory) {
        return yearsReward;
    }

    //   **************Free Claim Pool **************
    /**
     * @notice By calling this function the msg.sender will be enterd into free claim pool.
     * @dev Only callable once in a day.
     */
    function enterForFreeClaim() public {
        uint256 _day = findDay();
        uint256 _year = findYear();
        require(!isAlreadyEntered(_day, msg.sender), "Already Entered!");

        FreeClaimers memory tempClaimer = FreeClaimers(msg.sender, _year);
        todayFreeClaimers[_day].push(tempClaimer);

        emit EnteredForFreeClaim(_day, msg.sender);
    }

    /**
     * @notice By calling this function the msg.sender claims there reward from daily pool.
     * @dev Only callable if the msg.sender will be enterd in previous day free claim pool and not claim reward yet.
     */
    function freeClaim() public nonReentrant {
        uint _day = findDay();
        uint _preDay = _day - 1;
        require(_preDay >= 0, "Try at the end of day");
        require(
            isAlreadyEntered(_preDay, msg.sender),
            "Not in the Cliam list!"
        );
        require(!claimStatusFreePool[_preDay][msg.sender], "Alredy Claimed!");

        FreeClaimers memory currentClaimer = getFreeClaimerRecord(
            _preDay,
            msg.sender
        );
        uint256 rewardThisYear = yearsReward[currentClaimer.year];
        uint256 rewardPerDay = rewardThisYear.div(365);
        uint256 rewardforFreeClaimers = (rewardPerDay.mul(25)).div(100);
        uint256 allCliamers = countFreeClaimers(_preDay);
        uint256 todayShare = rewardforFreeClaimers.mul(10**DECIMAL);
        todayShare = todayShare.div(allCliamers);

        claimStatusFreePool[_preDay][msg.sender] = true;
        ptpToken.mintAmount(msg.sender, todayShare);

        emit ClaimedFreePTP(_preDay, todayShare, msg.sender);
    }

    //   ************** Reward Claim Pool **************
    /**
     * @notice By calling this function the msg.sender deposit there points in daily pointsReward pool.
     * @dev Only callable if the msg.sender have a pointsBalance entered number of points in contract.
     * @param _points the number of points user wants to deposit.
     */
    function depositPointsForReward(
        uint256 _points,
        Signature calldata _sign,
        uint256 nonce
    ) public nonReentrant {
        bytes32 sigHash = keccak256(
            abi.encodePacked(nonce, _sign.v, _sign.r, _sign.s)
        );
        require(!executed[sigHash], "Signature expired");
        executed[sigHash] = true;
        bool signaturesChecked = false;

        if (verifySignature(msg.sender, _points, _sign, nonce) == owner()) {
            signaturesChecked = true;
        }
        require(signaturesChecked, "Access restricted");

        uint256 _day = findDay();
        uint256 _year = findYear();
        if (isAlreadyExist(_day, msg.sender)) {
            uint index = getIndex(_day, msg.sender);
            todayDepositers[_day][index].amount += _points;
        } else {
            Depositers memory tempUser = Depositers(msg.sender, _points, _year);
            todayDepositers[_day].push(tempUser);
        }
        // pointsBalance[msg.sender] = pointsBalance[msg.sender].sub(_points);

        emit pointsDeposited(_day, _points, msg.sender, nonce);
    }

    /**
     * @notice By calling this function the msg.sender claims there reward from daily pointsReward pool.
     * @dev Only callable if the msg.sender will be enterd in previous day pointsReward pool and not claim reward yet.
     */
    function claimReward() public nonReentrant {
        uint _day = findDay();
        uint _preDay = _day - 1;
        require(_preDay >= 0, "Try at the end of day");
        require(isAlreadyExist(_preDay, msg.sender), "Invalid Claimer!");
        require(!claimStatusRewardPool[_preDay][msg.sender], "Alredy Claimed!");
        Depositers memory currentUser = getUserRecord(_preDay, msg.sender);

        uint256 rewardThisYear = yearsReward[currentUser.year];
        uint256 rewardPerDay = rewardThisYear.div(365);
        uint256 rewardAmount = rewardPerDay.mul(75);
        uint256 finalRewardAmount = rewardAmount.div(100);
        uint256 allPointsOfDay = totalDepositedPoints(_preDay);
        uint256 userAmount = currentUser.amount;
        userAmount = userAmount.mul(10**DECIMAL);
        uint256 userShare = userAmount.div(allPointsOfDay);
        uint256 userPTP = userShare.mul(finalRewardAmount);
        claimStatusRewardPool[_preDay][msg.sender] = true;
        ptpToken.mintAmount(msg.sender, userPTP);

        emit RewardClaimed(_preDay, userPTP, msg.sender);
    }

    /**
     * @notice Returns the number of users who deposited points for reward on given day in pointsReward pool.
     * @param _day Enter the day you want no of depositers.
     */
    function getNumberOfDepositers(uint256 _day) public view returns (uint) {
        return todayDepositers[_day].length;
    }

    /**
     * @notice Verify the signature are signed by admin.
     * @param _to user address that is signed by admin private key.
     * @param _amount is the number of points
     * @param signature object contains the admin signatures
     * @param _nonce is a payload that is signed with message
     * @return signer address that signs the message
     */
    function verifySignature(
        address _to,
        uint256 _amount,
        Signature calldata signature,
        uint256 _nonce
    ) public pure returns (address signer) {
        // 52 = message length
        string memory header = "\x19Ethereum Signed Message:\n84";

        // Perform the elliptic curve recover operation
        bytes32 messageHash = keccak256(
            abi.encodePacked(header, _to, _amount, _nonce)
        );

        return ecrecover(messageHash, signature.v, signature.r, signature.s);
    }

    //****************** Internals ******************

    /**
     * @notice Returns ture If given user already have a deposit in pointsReward pool else false.
     * @dev Internal function.
     * @param _day Enter the day.
     * @param _user address of the msg.sender
     */
    function isAlreadyExist(uint _day, address _user)
        internal
        view
        returns (bool)
    {
        Depositers[] memory tempUsers = todayDepositers[_day];
        bool userExist;
        uint allUsers = getNumberOfDepositers(_day);
        if (allUsers > 0) {
            for (uint256 i = 0; i < allUsers; i++) {
                if (tempUsers[i].user == _user) {
                    userExist = true;
                }
            }
        }
        return userExist;
    }

    /**
     * @notice Returns ture If given user already entered in freeclaim pool else false.
     * @dev Internal function.
     * @param _day Enter the day.
     * @param _user address of the msg.sender
     */
    function isAlreadyEntered(uint _day, address _user)
        internal
        view
        returns (bool)
    {
        FreeClaimers[] memory tempClaimers = todayFreeClaimers[_day];
        uint noOfClaimers = countFreeClaimers(_day);
        bool status = false;
        if (noOfClaimers > 0) {
            for (uint i = 0; i < noOfClaimers; i++) {
                if (tempClaimers[i].user == _user) {
                    status = true;
                }
            }
        }

        return status;
    }

    /**
     * @notice Returns the points deposited on the given day in pointsReward pool.
     * @param _day Enter the day.
     */
    function totalDepositedPoints(uint256 _day) public view returns (uint256) {
        Depositers[] memory tempUsers = todayDepositers[_day];
        uint256 amount;
        if (tempUsers.length > 0) {
            for (uint256 i = 0; i < tempUsers.length; i++) {
                amount += tempUsers[i].amount;
            }
        }
        return amount;
    }

    /**
     * @notice Return the user struct on the given day from pointsReward pool.
     * @param _day Enter the day.
     * @param _user adderss of the user
     * @return userRecord user Struct
     */
    function getUserRecord(uint _day, address _user)
        public
        view
        returns (Depositers memory)
    {
        Depositers[] memory tempUsers = todayDepositers[_day];
        Depositers memory userRecord;
        if (tempUsers.length > 0) {
            for (uint i = 0; i < tempUsers.length; i++) {
                if (tempUsers[i].user == _user) {
                    userRecord = tempUsers[i];
                }
            }
        }
        return userRecord;
    }

    /**
     * @notice Return the user deposited points on the given day from pointsReward pool.
     * @param _day Enter the day.
     * @param _user adderss of the user
     * @return amount user Deposit on given day
     */
    function getUserDeposit(uint _day, address _user)
        public
        view
        returns (uint)
    {
        Depositers[] memory tempUsers = todayDepositers[_day];
        uint amount;
        if (tempUsers.length > 0) {
            for (uint i = 0; i < tempUsers.length; i++) {
                if (tempUsers[i].user == _user) {
                    amount = tempUsers[i].amount;
                }
            }
        }
        return amount;
    }

    /**
     * @notice Return the user struct on the given day from freeClaim pool.
     * @param _day Enter the day.
     * @param _user adderss of the user
     * @return userRecord user Struct
     */
    function getFreeClaimerRecord(uint _day, address _user)
        public
        view
        returns (FreeClaimers memory)
    {
        FreeClaimers[] memory tempUsers = todayFreeClaimers[_day];
        require(tempUsers.length > 0, "Invalid Day");
        FreeClaimers memory claimerRecord;
        for (uint i = 0; i < tempUsers.length; i++) {
            if (tempUsers[i].user == _user) {
                claimerRecord = tempUsers[i];
            }
        }
        return claimerRecord;
    }

    /**
     * @notice Return the true,true if user enter on the given day in freepool.
     * @notice true,false if enter but not claim false,false not enter and not claimed.
     * @param _day Enter the day.
     * @param _user adderss of the user
     * @return isUser enter on the given day
     */
    function checkFreeDay(uint _day, address _user)
        public
        view
        returns (bool, bool)
    {
        bool isUser;
        bool claim = claimStatusFreePool[_day][_user];
        FreeClaimers[] memory tempUsers = todayFreeClaimers[_day];
        if (tempUsers.length > 0) {
            for (uint i = 0; i < tempUsers.length; i++) {
                if (tempUsers[i].user == _user) {
                    isUser = true;
                }
            }
        }

        return (isUser, claim);
    }

    /**
     * @notice Returns the index of the given user on specific day from pointsReward pool.
     * @param _day Enter the day.
     * @param _user adderss of the user
     * @return index
     */
    function getIndex(uint256 _day, address _user)
        public
        view
        returns (uint256)
    {
        Depositers[] memory tempUsers = todayDepositers[_day];
        require(tempUsers.length > 0, "Invalid Day");
        uint tempIndex;
        for (uint i = 0; i < tempUsers.length; i++) {
            if (tempUsers[i].user == _user) {
                tempIndex = i;
            }
        }
        return tempIndex;
    }
}

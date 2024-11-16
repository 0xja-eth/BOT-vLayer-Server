// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {EmailProver} from "./EmailProver.sol";

import {Proof} from "vlayer-0.1.0/Proof.sol";
import {Verifier} from "vlayer-0.1.0/Verifier.sol";

  enum TripStatus { Pending, Completed, Cancelled }

  struct Trip {
    address initiator; // Trip initiator
    uint256 value; // Payment value

    uint256 startTime; // Trip start time
    uint256 estEndTime; // Trip estimated end time
    uint256 actEndTime; // Trip actual end time

    TripStatus status;
  }

interface IBOTPlatform {
  function trips(string memory) external view returns (Trip memory);
  function currentTrips(address) external view returns (string memory);
  function emails(string memory) external view returns (address);

  function completeTrip(string memory _tripId, uint256 _actStartTime, uint256 _actEndTime) external;
}

contract EmailProofVerifier is Verifier {
  address public prover;
  address public botPlatform; // = 0xb4973806191F3D1B9Ee4c707B42ECBFCFCb2E8D6;

  int256 public timeZone = 7; // UTC+7

  constructor(address _prover, address _botPlatform) {
    prover = _prover;
    botPlatform = _botPlatform;
  }

  function verify(Proof calldata, string memory toEmail,
    string memory date, string memory pickupTime, string memory dropoffTime) public
  onlyVerified(prover, EmailProver.main.selector) {
    // Do anything...

    address toAddress = IBOTPlatform(botPlatform).emails(toEmail);
    string memory tripId = IBOTPlatform(botPlatform).currentTrips(toAddress);

    uint256 startTime = getTimestamp(date, pickupTime);
    uint256 endTime = getTimestamp(date, dropoffTime);

    IBOTPlatform(botPlatform).completeTrip(tripId, startTime, endTime);
  }

  // Utils

  function getTimestamp(string memory date, string memory time) public view returns (uint256) {
    (uint256 day, uint256 month, uint256 year) = parseDate(date);
    (uint256 hour, uint256 minute) = parseTime(time);
    uint256 daysSinceEpoch = daysFromDate(year, month, day);
    return uint256(int256((daysSinceEpoch * 86400) + (hour * 3600) + (minute * 60)) - (timeZone * 1 hours));
  }

  function parseDate(string memory date) internal pure returns (uint256 day, uint256 month, uint256 year) {
    bytes memory dateBytes = bytes(date);
    uint256 space1 = findSpaceIndex(dateBytes, 0);
    uint256 space2 = findSpaceIndex(dateBytes, space1 + 1);

    day = parseUint(substring(date, 0, space1));
    string memory monthName = substring(date, space1 + 1, space2);
    month = getMonthFromName(monthName);
    year = parseUint(substring(date, space2 + 1, dateBytes.length));
  }

  function parseTime(string memory time) internal pure returns (uint256 hour, uint256 minute) {
    bytes memory timeBytes = bytes(time);
    uint256 colonIndex = findColonIndex(timeBytes);

    hour = parseUint(substring(time, 0, colonIndex));
    minute = parseUint(substring(time, colonIndex + 1, timeBytes.length));
  }

  function getMonthFromName(string memory monthName) internal pure returns (uint256) {
    string[12] memory monthNames = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
    ];
    for (uint256 i = 0; i < 12; i++) {
      if (compareStrings(monthName, monthNames[i])) {
        return i + 1;
      }
    }
    revert("Invalid month name");
  }

  function daysFromDate(uint256 year, uint256 month, uint256 day) internal pure returns (uint256) {
    uint256 totalDays = 0;
    for (uint256 i = 1970; i < year; i++) {
      totalDays += isLeapYear(i) ? 366 : 365;
    }

    uint8[12] memory monthDays = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (isLeapYear(year)) {
      monthDays[1] = 29; // February has 29 days in a leap year
    }

    for (uint256 i = 1; i < month; i++) {
      totalDays += monthDays[i - 1];
    }

    totalDays += day - 1;
    return totalDays;
  }

  function isLeapYear(uint256 year) internal pure returns (bool) {
    if (year % 4 != 0) {
      return false;
    } else if (year % 100 != 0) {
      return true;
    } else if (year % 400 != 0) {
      return false;
    } else {
      return true;
    }
  }

  function findSpaceIndex(bytes memory str, uint256 start) internal pure returns (uint256) {
    for (uint256 i = start; i < str.length; i++) {
      if (str[i] == 0x20) { // Space character
        return i;
      }
    }
    revert("Space not found");
  }

  function findColonIndex(bytes memory str) internal pure returns (uint256) {
    for (uint256 i = 0; i < str.length; i++) {
      if (str[i] == 0x3A) { // Colon character
        return i;
      }
    }
    revert("Colon not found");
  }

  function substring(string memory str, uint256 startIndex, uint256 endIndex) internal pure returns (string memory) {
    bytes memory strBytes = bytes(str);
    bytes memory result = new bytes(endIndex - startIndex);
    for (uint256 i = startIndex; i < endIndex; i++) {
      result[i - startIndex] = strBytes[i];
    }
    return string(result);
  }

  function parseUint(string memory str) internal pure returns (uint256) {
    bytes memory bStr = bytes(str);
    uint256 result = 0;
    for (uint256 i = 0; i < bStr.length; i++) {
      if (bStr[i] >= 0x30 && bStr[i] <= 0x39) {
        result = result * 10 + (uint256(uint8(bStr[i])) - 48);
      } else {
        revert("Invalid character in number");
      }
    }
    return result;
  }

  function compareStrings(string memory a, string memory b) internal pure returns (bool) {
    return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
  }
}

//pragma solidity ^0.8.13;
//
//import {EmailProver} from "./EmailProver.sol";
//
//import {Proof} from "vlayer-0.1.0/Proof.sol";
//import {Verifier} from "vlayer-0.1.0/Verifier.sol";
//
//contract EmailProofVerifier is Verifier {
//    address public prover;
//
//    constructor(address _prover) {
//        prover = _prover;
//    }
//
//    function verify(Proof calldata, string memory toEmail,
//        string memory date, string memory pickupTime, string memory dropoffTime
//    ) public view onlyVerified(prover, EmailProver.main.selector) {
////        require(wallet == msg.sender, "Must be called from the same wallet as the registered address");
//    }
//}

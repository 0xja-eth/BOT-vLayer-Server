// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {EmailProver} from "./EmailProver.sol";
import {DateTimeUtils} from "./utils/DateTimeUtils.sol";

import {Proof} from "vlayer-0.1.0/Proof.sol";
import {Verifier} from "vlayer-0.1.0/Verifier.sol";
import "./utils/DateTimeUtils.sol";

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
    function trips(bytes memory) external view returns (Trip memory);
    function currentTrips(address) external view returns (bytes memory);
    function emails(string memory) external view returns (address);

    function completeTrip(bytes memory _tripId, uint256 _actStartTime, uint256 _actEndTime) external;
}

contract EmailProofVerifier is Verifier {
    address public prover;
    address public botPlatform;

    int256 public timeZone = 7; // UTC+7

    constructor(address _prover, address _botPlatform) {
        prover = _prover;
        botPlatform = _botPlatform;
    }

    function verify(Proof calldata, string memory toEmail,
        string memory date, string memory pickupTime, string memory dropoffTime) public
    onlyVerified(prover, EmailProver.main.selector) {
        address toAddress = IBOTPlatform(botPlatform).emails(toEmail);
        bytes memory tripId = IBOTPlatform(botPlatform).currentTrips(toAddress);

        uint256 startTime = DateTimeUtils.getTimestamp(date, pickupTime, timeZone);
        uint256 endTime = DateTimeUtils.getTimestamp(date, dropoffTime, timeZone);

        IBOTPlatform(botPlatform).completeTrip(tripId, startTime, endTime);
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
//    function verify(Proof calldata, address wallet, string memory body) public view onlyVerified(prover, EmailProver.main.selector) {
//        require(wallet == msg.sender, "Must be called from the same wallet as the registered address");
//    }
//}

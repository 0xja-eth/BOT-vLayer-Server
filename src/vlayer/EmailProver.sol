//pragma solidity ^0.8.28;

pragma solidity ^0.8.13;

import {Strings} from "openzeppelin-contracts/utils/Strings.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

import {Proof} from "vlayer-0.1.0/Proof.sol";
import {Prover} from "vlayer-0.1.0/Prover.sol";
import {RegexLib} from "vlayer-0.1.0/Regex.sol";
import {VerifiedEmail, UnverifiedEmail, EmailProofLib} from "vlayer-0.1.0/EmailProof.sol";

import {AddressParser} from "./utils/AddressParser.sol";

contract EmailProver is Prover, Ownable {
    using Strings for string;
    using RegexLib for string;
    using AddressParser for string;
    using EmailProofLib for UnverifiedEmail;

    string public targetDomain = "^.*?bangkok@bolt.eu.*?$";

    struct ProvedEmail {
        Proof proof;
        string toEmail;
        string pickupTime;
        string dropoffTime;
    }
    ProvedEmail[] public provedEmails;

    constructor() Ownable(msg.sender) { }

    function changeDomain(string memory _domain) external onlyOwner {
        targetDomain = _domain;
    }

    function main(UnverifiedEmail calldata unverifiedEmail,
        string memory to, string memory pickupTime, string memory dropoffTime
    ) public view returns (Proof memory, address, string memory, string memory) {
        VerifiedEmail memory email = unverifiedEmail.verify();

//        require(email.from.matches(targetDomain), "Email not from the bolt");
        require(email.to.matches(to), "Email not to the expected address");

        string[] memory captures = email.body.capture("^[\\s\\S]*<span>Pickup:</span>[\\s\\S]*?<span[^>]*>([\\d:]+)</span>[\\s\\S]*?<span>Dropoff:</span>[\\s\\S]*?<span[^>]*>([\\d:]+)</span>[\\s\\S]*$");

        require(captures.length == 3, "Subject must match the expected pattern");
        require(captures[1].equal(pickupTime), "Pickup time not match");
        require(captures[2].equal(dropoffTime), "Dropoff time not match");

        ProvedEmail memory pEmail = ProvedEmail(proof(), email.to, pickupTime, dropoffTime);
        provedEmails.push(pEmail);

        return (pEmail.proof, pEmail.to, pEmail.pickupTime, pEmail.dropoffTime);
    }
}

//import {Strings} from "openzeppelin-contracts/utils/Strings.sol";
//
//import {Proof} from "vlayer-0.1.0/Proof.sol";
//import {Prover} from "vlayer-0.1.0/Prover.sol";
//import {RegexLib} from "vlayer-0.1.0/Regex.sol";
//import {VerifiedEmail, UnverifiedEmail, EmailProofLib} from "vlayer-0.1.0/EmailProof.sol";
//
//import {AddressParser} from "./utils/AddressParser.sol";
//
//interface IExample {
//    function exampleFunction() external returns (uint256);
//}
//
//contract EmailProver is Prover {
//    using Strings for string;
//    using RegexLib for string;
//    using AddressParser for string;
//    using EmailProofLib for UnverifiedEmail;
//
//    function main(UnverifiedEmail calldata unverifiedEmail) public view returns (Proof memory, address, string memory) {
//        VerifiedEmail memory email = unverifiedEmail.verify();
//
//        string[] memory captures = email.subject.capture("^Welcome to vlayer, 0x([a-fA-F0-9]{40})!$");
//        require(captures.length == 2, "subject must match the expected pattern");
//        require(bytes(captures[1]).length > 0, "email header must contain a valid Ethereum address");
//        require(email.from.matches("^.*@vlayer.xyz$"), "from must be a vlayer address");
//
//        return (proof(), captures[1].parseAddress(), email.body);
//    }
//}
import fs from "fs";
import { createVlayerClient, preverifyEmail } from "@vlayer/sdk";
import {
  getConfig,
  createContext,
  deployVlayerContracts,
} from "@vlayer/sdk/config";

import proverSpec from "../out/EmailProver.sol/EmailProver";
import verifierSpec from "../out/EmailProofVerifier.sol/EmailProofVerifier";

// Delete the second DKIN-Signature in the email
// Delete the Content-Type: multipart/alternative; boundary="000000000000b1b1b305c0b3b3b3" in the email after "To"
const mimeEmail = fs.readFileSync("./testdata/bolt-email.eml").toString();
const unverifiedEmail = await preverifyEmail(mimeEmail);

const platformAddress = process.env.PLATFORM_ADDRESS;

// const platformAddress = "0xb4973806191F3D1B9Ee4c707B42ECBFCFCb2E8D6" // Devnet
// const {ethClient, chain, account} = await createContext(getConfig());
// await ethClient.deployContract({
//   chain,
//   account,
//   args: ['0x13a4d9ed1a36d6fa203212aa71e594d70eb6cab6', platformAddress],
//   abi: verifierSpec.abi,
//   bytecode: verifierSpec.bytecode.object,
//
// })
// throw 'end'

console.log("platformAddress:", platformAddress);

const { prover, verifier } = await deployVlayerContracts({
  proverSpec,
  verifierSpec,
  verifierArgs: [platformAddress],
});

console.log("Prover:", prover, "Verifier:", verifier);

// const prover = "0x9c107e40d560a13449ed7b12f01d01dea88ea33f";
// const verifier = "0x05a4b5e04d625eec182bd0898e8adfe20cf5a857";
//
// const config = getConfig();
// const { chain, ethClient, account, proverUrl, confirmations } =
//   await createContext(config);
//
// console.log("Proving...");
//
// const vlayer = createVlayerClient({
//   url: proverUrl,
// });
//
// console.log("Prover:", prover);
//
// const hash = await vlayer.prove({
//   address: prover,
//   proverAbi: proverSpec.abi,
//   functionName: "main",
//   chainId: chain.id,
//   // args: [unverifiedEmail, "^.*?804173948@qq\\.com.*?$", "20:33", "20:44"],
//   args: [unverifiedEmail, "^.*?0xja\\.eth@gmail\\.com.*?$", "15 November 2024", "20:33", "20:44"],
// });
//
// const result = await vlayer.waitForProvingResult(hash);
// console.log("Proof:", result);
//
// fs.writeFileSync("./testdata/bolt-email-proof.json", JSON.stringify(result, undefined, 2));
//
// console.log("Verifying...");
//
// // const result = JSON.parse(fs.readFileSync("./testdata/bolt-email-proof.json").toString());
//
// const txHash = await ethClient.writeContract({
//   address: verifier,
//   abi: verifierSpec.abi,
//   functionName: "verify",
//   args: result,
//   chain,
//   account: account,
// });
//
// await ethClient.waitForTransactionReceipt({
//   hash: txHash,
//   confirmations,
//   retryCount: 60,
//   retryDelay: 1000,
// });
//
// console.log("Verified!");

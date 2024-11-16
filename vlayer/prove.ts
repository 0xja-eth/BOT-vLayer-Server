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

const platformAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512" // Devnet

const { prover, verifier } = await deployVlayerContracts({
  proverSpec,
  verifierSpec,
  proverArgs: [],
  verifierArgs: [platformAddress]
});

const config = getConfig();
const { chain, ethClient, account, proverUrl, confirmations } =
  await createContext(config);

console.log("Proving...");

const vlayer = createVlayerClient({
  url: proverUrl,
});

console.log("Prover:", prover);

const hash = await vlayer.prove({
  address: prover,
  proverAbi: proverSpec.abi,
  functionName: "main",
  chainId: chain.id,
  // args: [unverifiedEmail, "^.*?804173948@qq\\.com.*?$", "20:33", "20:44"],
  args: [unverifiedEmail, "^.*?0xja\\.eth@gmail\\.com.*?$", "20:33", "20:44"],
});
const result = await vlayer.waitForProvingResult(hash);
console.log("Proof:", result);

console.log("Verifying...");

const txHash = await ethClient.writeContract({
  address: verifier,
  abi: verifierSpec.abi,
  functionName: "verify",
  args: result,
  chain,
  account: account,
});

await ethClient.waitForTransactionReceipt({
  hash: txHash,
  confirmations,
  retryCount: 60,
  retryDelay: 1000,
});

console.log("Verified!");

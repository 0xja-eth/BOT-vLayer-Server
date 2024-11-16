import express, { Request, Response } from 'express';
import fs from 'fs';
import { createVlayerClient, preverifyEmail } from '@vlayer/sdk';
import { getConfig, createContext } from '@vlayer/sdk/config';
import proverSpec from '../out/EmailProver.sol/EmailProver';
import verifierSpec from '../out/EmailProofVerifier.sol/EmailProofVerifier';

// Configure Express application
const app = express();
const PORT = 3001;

// Enable JSON body parsing
app.use(express.json());

// Define prover and verifier addresses as constants
const prover = process.env.PROVER_ADDRESS;
const verifier = process.env.VERIFIER_ADDRESS;

console.log({ prover, verifier })

// Route to handle generating proof from EML content
app.post('/generate-proof', async (req: Request, res: Response) => {
  try {
    // Retrieve EML content from request body
    const { emlContent } = req.body;

    if (!emlContent) {
      return res.status(400).send('Please provide EML content');
    }

    // Pre-verify the email content
    const unverifiedEmail = await preverifyEmail(emlContent);

    // Get configuration information
    const config = getConfig();
    const { chain, ethClient, account, proverUrl, confirmations } = await createContext(config);

    // Create vlayer client
    const vlayer = createVlayerClient({
      url: proverUrl,
    });

    // Call the prove method
    console.log('Proving...');
    const hash = await vlayer.prove({
      address: prover,
      proverAbi: proverSpec.abi,
      functionName: 'main',
      chainId: chain.id,
      args: [unverifiedEmail, '^.*?0xja\\.eth@gmail\\.com.*?$', '15 November 2024', '20:33', '20:44'],
    });

    // Wait for the proof result
    const proofResult = await vlayer.waitForProvingResult(hash);
    console.log('Proof:', proofResult);

    // Save the proof result to a file
    fs.writeFileSync('./testdata/bolt-email-proof.json', JSON.stringify(proofResult, undefined, 2));

    console.log('Verifying...');

    // Call the verify method on the smart contract
    const txHash = await ethClient.writeContract({
      address: verifier,
      abi: verifierSpec.abi,
      functionName: 'verify',
      args: proofResult,
      chain,
      account: account,
    });

    // Wait for transaction confirmation
    await ethClient.waitForTransactionReceipt({
      hash: txHash,
      confirmations,
      retryCount: 60,
      retryDelay: 1000,
    });

    console.log('Verified!');

    // Return the verification result to the client
    res.json({
      message: 'Verification successful',
      proofResult,
      txHash,
    });
  } catch (error) {
    console.error('Server error:', error);
    res.status(500).send('Server error');
  }
});

// Start the Express server
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}...`);
});

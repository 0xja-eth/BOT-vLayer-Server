import express, { Request, Response } from 'express';
import fs from 'fs';
import multer from 'multer';
import { createVlayerClient, preverifyEmail } from '@vlayer/sdk';
import { getConfig, createContext } from '@vlayer/sdk/config';
import proverSpec from '../out/EmailProver.sol/EmailProver';
import verifierSpec from '../out/EmailProofVerifier.sol/EmailProofVerifier';

// Configure Express application
const app = express();
const PORT = 3001;

// Enable JSON body parsing
app.use(express.json());

// Set up multer for file uploads (temporary storage in the 'uploads' folder)
const upload = multer({ dest: 'uploads/' });

// Define prover and verifier addresses as constants
const prover = process.env.PROVER_ADDRESS;
const verifier = process.env.VERIFIER_ADDRESS;

console.log({ prover, verifier });

// Route to handle generating proof from EML file upload
app.post('/api/generate-proof/:email', upload.single('emlFile'), async (req: Request, res: Response) => {
  try {
    // Check if the file was uploaded
    if (!req.file) {
      return res.status(400).send('Please upload an EML file');
    }

    const { email } = req.params;

    // Read the content of the uploaded EML file
    const emlContent = fs.readFileSync(req.file.path, 'utf-8');

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
      args: [unverifiedEmail, `^.*?${email}.*?$`, '15 November 2024', '20:33', '20:44'],
      // args: [unverifiedEmail, '^.*?0xja\\.eth@gmail\\.com.*?$', '15 November 2024', '20:33', '20:44'],
    });

    // Wait for the proof result
    const proofResult = await vlayer.waitForProvingResult(hash);
    console.log('Proof:', proofResult);

    // Tmp Fix:
    // proofResult[0].callGuestId = "0xc0f59f76de44b1700c2de89e0eeffbbad523e049b6beef55441f371811f62767"

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

    // Delete the uploaded file after processing
    fs.unlink(req.file.path, (err) => {
      if (err) console.error('Error deleting the temporary file:', err);
    });

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

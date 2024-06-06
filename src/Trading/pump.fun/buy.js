const {
  Program,
  AnchorProvider,
  setProvider,
  Wallet,
} = require("@coral-xyz/anchor");
const {
  Connection,
  Keypair,
  PublicKey,
  VersionedTransaction,
  TransactionMessage,
} = require("@solana/web3.js");
const base58 = require("bs58");
const {
  createAssociatedTokenAccount,
  findAssociatedTokenAddress,
  getbondingCurveFromToken,
} = require("./utils");
const { BN } = require("bn.js");
const { idl } = require("./idl");
const { PUMP_FUN_PROGRAM_ID } = require("./constants");
const { connection, wallet } = require("../../helpers/config");
const { checkTx, getDecimals } = require("../../helpers/util");

async function buy(tokenAddress, amtOfSolToSpend) {
  // things we need
  const pump_fun_program_id = new PublicKey(PUMP_FUN_PROGRAM_ID);
  // owner = wallet, that we already defined in src/helpers/config.js
  const owner = new Wallet(wallet);
  const mint = new PublicKey(tokenAddress);

  // logic to buy using the pump.fun program
  const { bondingCurve, associatedBondingCurve } =
    await getbondingCurveFromToken(tokenAddress);
  const tokenAccount = await findAssociatedTokenAddress(wallet.publicKey, mint);
  const provider = new AnchorProvider(
    connection,
    owner,
    AnchorProvider.defaultOptions()
  );
  setProvider(provider);
  const program = new Program(idl, pump_fun_program_id, provider);
  const associatedTokenAccount = await createAssociatedTokenAccount(
    connection,
    wallet,
    mint
  );
  // pump.fun.buy(arg1: tokenamount, arg2: solamount)
  const instruction = program.methods
    .buy(new BN(0), new BN(amtOfSolToSpend * 10 ** 9))
    .accounts({
      global: new PublicKey("4wTV1YmiEkRvAtNtsSGPtUrqRYQMe5SKy2uB4Jjaxnjf"),
      feeRecipient: new PublicKey(
        "CebN5WGQ4jvEPvsVU4EoHEpgzq1VV7AbicfhtW4xC9iM"
      ),
      mint: mint,
      bondingCurve: new PublicKey(bondingCurve),
      associatedBondingCurve: new PublicKey(associatedBondingCurve),
      associatedUser: tokenAccount,
      user: wallet.publicKey,
      systemProgram: new PublicKey("11111111111111111111111111111111"),
      tokenProgram: new PublicKey(
        "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
      ),
      rent: new PublicKey("SysvarRent111111111111111111111111111111111"),
      eventAuthority: PublicKey.findProgramAddressSync(
        [Buffer.from("__event_authority")],
        pump_fun_program_id
      )[0],
      program: pump_fun_program_id,
    })
    .instruction();
  const instructions = [];
  instructions.push(instruction);
  const blockhash = await connection.getLatestBlockhash("finalized");
  const final_tx = new VersionedTransaction(
    new TransactionMessage({
      payerKey: wallet.publicKey,
      recentBlockhash: blockhash.blockhash,
      instructions: instructions,
    }).compileToV0Message()
  );
  final_tx.sign([owner.payer]);
  const txid = await connection.sendTransaction(final_tx, {
    skipPreflight: true,
  });

  const success = await checkTx(txid);
  if (success) {
    console.log(`🚀 successfully bought ${tokenAddress}`);
    console.log(`https://solscan.io/tx/${txid}?cluster=mainnet`);
  } else {
    console.log(`❌ failed to buy ${tokenAddress}`);
    console.log("trying again...");
    await buy(tokenAddress, amtOfSolToSpend);
  }
}

### tea

forge verify-contract 0x4fD5cEb2C0dEE34E78f6f7A5fbc2662EB46763fD TokenDeploy --verifier-url https://api-sepolia.etherscan.io/api --constructor-args 0000000000000000000000005D435ac154d9188621275998dAB6249Fac149C41 --chain 11155111

forge verify-contract 0x7eaA67f8D365BBe27D6278fDc2ba24a1aa71C8e5 Tea --verifier-url https://api-sepolia.etherscan.io/api --constructor-args 0000000000000000000000004fD5cEb2C0dEE34E78f6f7A5fbc2662EB46763fD --chain 11155111

forge verify-contract 0x7ea3951648b1631425915C7F1C5D3f73dECC26C9 MintManager --verifier-url https://api-sepolia.etherscan.io/api --constructor-args 0000000000000000000000005d435ac154d9188621275998dab6249fac149c410000000000000000000000007eaa67f8d365bbe27d6278fdc2ba24a1aa71c8e5 --chain 11155111


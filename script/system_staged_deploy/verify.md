### tea

#### SEPOLIA

forge verify-contract 0x4fD5cEb2C0dEE34E78f6f7A5fbc2662EB46763fD TokenDeploy --verifier-url
https://api-sepolia.etherscan.io/api --constructor-args 0000000000000000000000005D435ac154d9188621275998dAB6249Fac149C41
--chain 11155111

forge verify-contract 0x7eaA67f8D365BBe27D6278fDc2ba24a1aa71C8e5 Tea --verifier-url https://api-sepolia.etherscan.io/api
--constructor-args 0000000000000000000000004fD5cEb2C0dEE34E78f6f7A5fbc2662EB46763fD --chain 11155111

forge verify-contract 0x7ea3951648b1631425915C7F1C5D3f73dECC26C9 MintManager --verifier-url
https://api-sepolia.etherscan.io/api --constructor-args
0000000000000000000000005d435ac154d9188621275998dab6249fac149c410000000000000000000000007eaa67f8d365bbe27d6278fdc2ba24a1aa71c8e5
--chain 11155111

#### MAINNET

<!-- forge verify-contract 0xd736AdFAD4C07c3fEc73993dd2e694db1b31C435 TokenDeploy --verifier-url 'https://sepolia.tea.xyz/api/' --constructor-args 000000000000000000000000cDb68686290310dD8623371E1db53157dB6b8cA1 --chain 10218 --verifier blockscout -->

forge verify-contract 0xd736AdFAD4C07c3fEc73993dd2e694db1b31C435 TokenDeploy --verifier-url
'https://api.etherscan.io/v2/api' --constructor-args 000000000000000000000000cDb68686290310dD8623371E1db53157dB6b8cA1
--chain 1

forge verify-contract 0x7Eaf50f5C8eab3B4b9AADF86AC6cCDCA9f2EB250 TimelockController --verifier-url
'https://api.etherscan.io/v2/api' --constructor-args
0000000000000000000000000000000000000000000000000000000000015180000000000000000000000000cdb68686290310dd8623371e1db53157db6b8ca1000000000000000000000000cdb68686290310dd8623371e1db53157db6b8ca1000000000000000000000000cdb68686290310dd8623371e1db53157db6b8ca1
--chain 1

forge verify-contract 0x7Ea27904Af7EEfB5a8c3ce973b2EE4670e2815D3 Tea --verifier-url 'https://api.etherscan.io/v2/api'
--constructor-args
000000000000000000000000d736AdFAD4C07c3fEc73993dd2e694db1b31C43500000000000000000000000007EAEad8a44ceCE3c274e60c82989300D803fF82A000000000000000000000000cdb68686290310dd8623371e1db53157db6b8ca1
--chain 1

forge verify-contract 0x7ea3951648b1631425915C7F1C5D3f73dECC26C9 MintManager --verifier-url
'https://api.etherscan.io/v2/api' --constructor-args
000000000000000000000000cdb68686290310dd8623371e1db53157db6b8ca10000000000000000000000007Ea27904Af7EEfB5a8c3ce973b2EE4670e2815D3
--chain 1

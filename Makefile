.DEFAULT_GOAL := help
ERROR := "\033[31m[%s]\033[0m %s\n"

.ONESHELL: check-contract-chain hardhat-deploy

hardhat-compile: # Compile the smart contract with hardhat
	@npx hardhat compile

hardhat-deploy: check-contract-chain # Deploy the smart contract to the chain specified in CONTRACT_CHAIN
	@npx hardhat run scripts/deploy.js --network ${CONTRACT_CHAIN}

hardhat-verify: check-contract-address check-contract-chain# Verify the smart contract at the address specified in CONTRACT_ADDR to publish in etherscan
	@npx hardhat verify --network ${CONTRACT_CHAIN} ${CONTRACT_ADDR}

check-contract-address: # Make sure the CONTRACT_ADDR env variable is specified
ifndef CONTRACT_ADDR
	@printf $(ERROR) "CONTRACT_ADDR test not defined. Run 'export CONTRACT_ADDR=<contract address>'. Exiting."
	exit 1
endif


check-contract-chain: # Make sure the CONTRACT_CHAIN env variable is specified
ifndef CONTRACT_CHAIN
	@printf $(ERROR) "CONTRACT_CHAIN test not defined. Run 'export CONTRACT_CHAIN=<contract chain>'. For testing use 'export CONTRACT_CHAIN=sepolia'. Exiting."
	exit 1
endif

help: # Print help on Makefile
	@grep '^[^.#]\+:\s\+.*#' Makefile | \
	sed "s/\(.\+\):\s*\(.*\) #\s*\(.*\)/`printf "\033[93m"`\1`printf "\033[0m"`     \3 [\2]/" | \
	expand -t20
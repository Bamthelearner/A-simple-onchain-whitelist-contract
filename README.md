Please remember to replace the address and private key in testnet-account in flow.js or you will be using my testnet account.

First we have to create a campaign (We need a campaign to let us in, right?)

	//Arguements { CampaignName : String, StartTime : UFix64?, EndTime : UFix64?, CampaignCap : UInt64? }
	//That means we are creating a campaign named "1", have no time limit (start nor end) and maximum capacity of 100 people

`flow transactions send "./cadence/Transaction/Create Campaign.cdc" 1 nil nil 100 -n=testnet --signer=testnet-account`


Then we can try register the campaign as a user (you cannot register on behalf of others)

	//Arguements { CampaignName : String, CampaignHolderAddress : Address }
	//That means we are registering ourself to a campaign named "1" which is held by account 0x31c180bc6c06cc0e

`flow transactions send "./cadence/Transaction/Register Address.cdc" 1 0x31c180bc6c06cc0e -n=testnet --signer=testnet-account`

Then we can check if the campaign has us registered

	//Arguements { CampaignName : String, CampaignHolderAddress : Address }
	//That means we are checking the registered addresses under campaign named "1" which is held by account 0x31c180bc6c06cc0e

`flow  scripts execute "./cadence/Script/Read Campaign Registered Address.cdc" 1 0x31c180bc6c06cc0e -n=testnet`


After playing as a user, lets role ourself as Emerald Bot~


First, we have to give out the capability to bulk register (in this case, we give the capability to ourselves)

	//Arguements { CampaignName : String, receiveraddr : Address }
	//That means we giving this capability of campaign named "1" to the address 0x31c180bc6c06cc0e

`flow transactions send "./cadence/Transaction/Proxy Function/Give Cap.cdc" 1 0x31c180bc6c06cc0e -n=testnet --signer=testnet-account`

Then we can bulk register addresses on behalf of othersssss!

	//Arguements { CampaignName : String, Campaignaddr : Address, addrlist: [Address] }
	//That means we are registering a list of addresses to a campaign named "1" under address 0x31c180bc6c06cc0e

`flow transactions send "./cadence/Transaction/Proxy Function/Proxy Register.cdc" 1 0x31c180bc6c06cc0e [0xc68c624ebbbd3aa9,0xc68c624ebbbd3aa0] -n=testnet --signer=testnet-account`

Yeahhhh we did it!~~~~~~~~

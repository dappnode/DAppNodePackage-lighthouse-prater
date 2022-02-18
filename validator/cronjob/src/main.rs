use reqwest::Error;
use serde::{Deserialize};
use std::fmt::Debug;

// TODO
// - setup server mock for web3signer and lighthouse remote API keymanager
// - check env variable production or testing and return correct url
// - finish compare function


static HTTP_WEB3SIGNER: &str = "http://web3signer.web3signer-prater.dappnode:9000/eth/v1/keystores";
static HTTP_WEB3SIGNER_DEV: &str = "https://8aca467a-9f52-4a67-8318-115e49f8ae90.mock.pstmn.io/localhost:9000/eth/v1/keystores";


// REMOTE SIGNER

#[derive(Deserialize, Debug)]
struct GetRemoteSignerValidators {
    data: Vec<PublicKeysRemoteSigner>
}

#[derive(Deserialize, Debug)]
struct PublicKeysRemoteSigner {
    validating_pubkey: String,
    derivation_path: String,
    readonly: bool
}


impl GetRemoteSignerValidators {
    fn print_data(&self) {
        println!("{:#?}", self.data);
    }
    
    fn new() -> Result<Self, Error> {
    }

    async fn fetch_public_keys() -> Result<GetRemoteSignerValidators, String> {
        // fetch API from HTTP_WEB3SIGNER and parse the output in json format
        let client = reqwest::Client::new();
        let response = client.get(HTTP_WEB3SIGNER_DEV).send().await.unwrap();
        // parse response to json
        let json: GetRemoteSignerValidators = response.json::<GetRemoteSignerValidators>().await.unwrap();

        // return the parsed json as a Response struct
        Ok(json)
    }
}

// LIGHTHOUSE-GET

#[derive(Deserialize, Debug)]
struct GetLighthouseValidators {
    data: Vec<PublicKeysLighthouse>
}

#[derive(Deserialize, Debug)]
struct PublicKeysLighthouse {
    enabled: bool,
    description: String,
    readvoting_pubkeyonly: String
}

impl GetLighthouseValidators {
    fn print_data(&self) {
        println!("{:#?}", self.data);
    }

    // function that return 

    async fn fetch_public_keys() -> Result<&GetLighthouseValidators, String> {
        // fetch API from HTTP_WEB3SIGNER and parse the output in json format
        let client = reqwest::Client::new();
        let response = client.get(HTTP_WEB3SIGNER_DEV).send().await.unwrap();
        // parse response to json
        let json: GetLighthouseValidators = response.json::<GetLighthouseValidators>().await.unwrap();

        // return the parsed json as a Response struct
        Ok(&json)
    }
}


// LIGHTHOUSE-POST

#[derive(Deserialize, Debug)]
struct PostLighthouseValidators {}

impl PostLighthouseValidators {
    async fn post_keys() -> Result<PostLighthouseValidators, String> {
        // fetch API from HTTP_WEB3SIGNER and parse the output in json format
        let client = reqwest::Client::new();
        let response = client.post(HTTP_WEB3SIGNER_DEV).send().await.unwrap();
        // parse response to json
        let json: PostLighthouseValidators = response.json::<PostLighthouseValidators>().await.unwrap();

        // return the parsed json as a Response struct
        Ok(json)
    }
}



#[tokio::main]
async fn main() -> Result<(), Error> {
    println!("Starting cronjob");
    
    let public_keys_remote = GetRemoteSignerValidators::fetch_public_keys().await.unwrap();
    public_keys_remote.print_data();

    let public_keys_lighthouse = GetLighthouseValidators::fetch_public_keys().await.unwrap();
    public_keys_lighthouse.print_data();

    compare_public_keys(public_keys_remote: &Vec<PublicKeysRemoteSigner>, public_keys_lighthouse: &Vec<PublicKeysLighthouse>);


    println!("Finished cronjon");
    Ok(())
}

fn compare_public_keys(public_keys_remote: &Vec<PublicKeysRemoteSigner>, public_keys_lighthouse: &Vec<PublicKeysLighthouse>) {
    // compare the public keys from the remote signer and the lighthouse
    // if the public keys are the same, do nothing
    // if the public keys are different, update the lighthouse
    // if the public keys are missing in lighthouse, add the public key to lighthouse
    // if the public keys are missing in remote signer, remove the public key from lighthouse
    // if the public keys are missing in both lighthouse and remote signer, do nothing
    // if the public keys are missing in lighthouse and remote signer, do nothing

    // TODO



}
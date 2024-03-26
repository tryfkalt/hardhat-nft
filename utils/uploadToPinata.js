const pinataSDK = require("@pinata/sdk");
const path = require("path");
const fs = require("fs");
require("dotenv").config();

const pinataApiKey = process.env.PINATA_API_KEY;
const pinataApiSecret = process.env.PINATA_API_SECRET;
const pinata = pinataSDK(pinataApiKey, pinataApiSecret);

async function storeImages(imagesFilePath) {
  const fullImagesPath = path.resolve(imagesFilePath); // get the full path to the images
  // the fullImagesPath should be the path to the image you want to upload
  const files = fs.readdirSync(fullImagesPath); // read all files in the directory
  let responses = [];
  console.log("Uploading images to Pinata...");
  for (fileIndex in files) {
    // this is creating a readable stream from the file
    // which means that we can pipe the file to Pinata
    const readableStreamForFile = fs.createReadStream(`${fullImagesPath}/${files[fileIndex]}`);
    try {
      const response = await pinata.pinFileToIPFS(readableStreamForFile);
      responses.push(response);
    } catch (error) {
      console.log(error);
    }
  }
  return { responses, files };
}

async function storeTokenUriMetadata(metadata) {
  // store the metadata in IPFS
  try {
    const response = await pinata.pinJSONToIPFS(metadata);
    return response;
  } catch (error) {
    console.log(error);
  }
}
module.exports = { storeImages, storeTokenUriMetadata };

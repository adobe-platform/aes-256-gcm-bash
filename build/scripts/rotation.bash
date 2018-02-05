#!/bin/bash

function guards() {
  if [ -z "$s3Bucket" ] || [ -z "$s3SrcDir" ] || [ -z "$s3DestinationDir" ]; then
    echo "usage: s3Bucket=<s3-bucket> s3SrcDir=<dir-in-s3-raw-secrets> s3DestinationDir=<upload-s3-dir> <script>"
    exit 1
  fi

  if ! which aes-256-gcm-bash; then
    echo "This repo does not seem to have been installed on the system"
    echo "Please cd into the root and run 'make install'"
    exit 1
  fi

  if [ -z "$AWS_REGION" ]; then
    echo "AWS_REGION not set, exiting"
    exit 1
  fi

  if [ -z "$KMS_CIPHERTEXT" ] && [ -z "$KMS_KEY_ARN" ]; then
    echo "Neither KMS_KEY_ARN nor KMS_CIPHERTEXT are set, exiting"
    exit 1
  fi
}

guards

if [ -z "$KMS_CIPHERTEXT" ]; then
  export KMS_CIPHERTEXT="$(aes-256-gcm-bash kms-key | tail -n2  | tr -d "[:blank:]" | tr -d "\n")"
  echo "Fetched ciphertext from KMS: $KMS_CIPHERTEXT"
else
  echo "Using KMS_CIPHERTEXT set in env"
fi

cwd="$(pwd)"
pathToRawFiles="${s3Bucket}/${s3SrcDir}"
pathToEncryptedFiles="${s3Bucket}/${s3DestinationDir}"

# ---- Download all secrets
# following subject to change - may want to switch download src to secrets server
echo "=============== DOWNLOADING FROM s3://$pathToRawFiles to ./$pathToRawFiles"
mkdir -p "$cwd/$pathToRawFiles"
cd "$cwd/$pathToRawFiles"
aws s3 cp "s3://$pathToRawFiles" . --recursive
cd "$cwd"

# ---- Encrypt all secrets
echo "=============== ENCRYPTING FILES INTO $pathToEncryptedFiles"
rm -rf "$pathToEncryptedFiles"
cp -R "$cwd/$pathToRawFiles" "$cwd/$pathToEncryptedFiles"

cd "$cwd/$pathToEncryptedFiles"
for file in $(ls -a); do
  if [ "$file" == "." ] || [ "$file" == ".." ]; then
    continue
  fi
  aes-256-gcm-bash encrypt-kms secret=$file cleanroom=true
done
cd "$cwd"

# ---- Reupload all the things
echo "=============== COPYING TO s3://$pathToEncryptedFiles"
cd "$cwd/$pathToEncryptedFiles"
for file in $(ls -a | grep '-encrypted.json$'); do
  aws s3 cp "$cwd/$pathToEncryptedFiles/$file" "s3://$pathToEncryptedFiles/"
done

guard-%: 
	@if [ -z "${${*}}" ]; then echo "REQUIRED env-var $* not set" && exit 1; fi

kms-key: guard-AWS_REGION
kms-key: guard-KMS_KEY_ARN 
kms-key:
	@$(eval KMS_CIPHERTEXT:=$(shell aws kms generate-data-key --key-id ${KMS_KEY_ARN} --key-spec AES_128 --query CiphertextBlob --output text --region ${AWS_REGION}))

	@echo "Retreived Ciphertext from KMS: \n\t${KMS_CIPHERTEXT}\n"

kms-get-secret: guard-AWS_REGION
kms-get-secret: guard-KMS_CIPHERTEXT
kms-get-secret:
	@$(eval AES_256_GCM_SECRET:=$(shell echo "${KMS_CIPHERTEXT}" | base64 --decode | aws kms decrypt --ciphertext-blob fileb:///dev/stdin --region ${AWS_REGION} --output text --query Plaintext | xxd -pu))

	@echo "Decrypted KMS_CIPHERTEXT.'"
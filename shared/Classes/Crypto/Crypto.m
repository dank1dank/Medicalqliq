//
//  Crypto.m
//  CCiPhoneApp
//
//  Created by Adam Sowa on 8/17/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "Crypto.h"

#import "UserSessionService.h"
#import "qxlib/platform/ios/QxPlatfromIOS.h"

#define KEY_BIT_SIZE 2048
#define RSA_KEY_HEADER_PREFIX @"-----BEGIN RSA "

static Crypto *_instance = nil;

static int mkcert2(X509 **x509p, EVP_PKEY **pkeyp, int bits, int serial, int days);

@interface Crypto()

- (void) setDefaultPaths: (NSString *)userName;
- (BOOL) readKeysFromDisk: (NSString *)password;
- (BOOL) readKeysFromKeychain: (NSString *)username withPassword:(NSString *)password;
- (void) writeKeys: (NSString *)password;
- (void) generateKeys: (NSString *)password;
- (NSString *) decryptFromBase64: (NSString *) encryptedBase64 wasOk:(BOOL *)ok;
+ (NSString *) decryptFromBase64: (NSString *) encryptedBase64 privateKey:(NSString *)privateKey password:(NSString *)password wasOk:(BOOL *)ok;

+ (NSString *) decryptFromBase64: (NSString *) encryptedBase64 wasOk:(BOOL *)ok privateKey:(EVP_PKEY *)privKey;

- (void) storeKeysInKeychainForUsername: (NSString *)username;
- (void) deleteKeysInKeychainForUsername: (NSString *)username;
- (void) freeKeys;

+ (NSString *) encryptToBase64: (NSString *)plainData: (NSString *)pubKeyString;
+ (void *) readKeyFromString: (NSString *)pubKeyString: (KeyType)type;
+ (void *) readKeyFromString: (NSString *)pubKeyString type:(KeyType)type withPassword:(NSString*)password;
+ (NSString *) keyToString: (void *)key type:(KeyType)type withPassword:(NSString*)password;

@end

@implementation Crypto

@synthesize publicKeyString;
@synthesize privateKeyString;
@synthesize currentUserName;

- (id) init
{
	if (self = [super init]) {
		privateKey = NULL;
		publicKey = NULL;
		publicKeyString = privateKeyString = @"";
		
		CRYPTO_malloc_init();
		CRYPTO_mem_ctrl(CRYPTO_MEM_CHECK_ON);
		OpenSSL_add_all_algorithms();
		OpenSSL_add_all_digests();		
	}
	return self;
}

- (void) dealloc
{
	
#ifndef OPENSSL_NO_ENGINE
    ENGINE_cleanup();
#endif
    CRYPTO_cleanup_all_ex_data();	
	EVP_PKEY_free((EVP_PKEY *)privateKey);
	EVP_PKEY_free((EVP_PKEY *)publicKey);
	[publicKeyString release];
	[privateKeyString release];
	[currentUserName release];
	[super dealloc];
}

+ (id) instance {
    @synchronized(self) {
        if(_instance == nil)
            _instance = [[super allocWithZone:NULL] init];
    }
    return _instance;
}

- (void) initForUser: (NSString *)userName: (NSString *)password
{
//	[self setDefaultPaths: userName];
	BOOL ret = [self openForUser: userName: password];
	if (!ret) {
        DDLogSupport(@"Cannot open crypto for user, will generate new keys now");
		[self generateKeys: password];
		[self storeKeysInKeychainForUsername: userName];
        self.currentUserName = userName;
	}
}

- (BOOL) openForUser: (NSString *)newUserName withPassword:(NSString *)password
{
    if (currentUserName && [currentUserName isEqualToString:newUserName])
        return YES;
    else {
        BOOL ret = [self readKeysFromKeychain: newUserName withPassword: password];
        if (ret)
            self.currentUserName = newUserName;            
        return ret;
    }
}

- (BOOL) saveKeysForUser:(NSString *)userName: (NSString *)password privateKey:(NSString *)privKeyString publicKey:(NSString *)pubKeyString
{
    BOOL ret = NO;
    [self freeKeys];
    
    @synchronized (self) {
        privateKey = (EVP_PKEY *) [Crypto readKeyFromString: privKeyString type: PrivateKey withPassword: password];
        publicKey = (EVP_PKEY *)[Crypto readKeyFromString: pubKeyString type: PublicKey withPassword: nil];
    }
    
    if (privateKey && publicKey) {
        self.privateKeyString = privKeyString;
        self.publicKeyString = pubKeyString;
        self.currentUserName = userName;
        [self storeKeysInKeychainForUsername:userName];
        [QxPlatfromIOS setKeyPair:publicKey publicKeyString:publicKeyString privateKey:privateKey];
        ret = YES;
        DDLogSupport(@"Succesfully stored key pair for user");
    } else {
        DDLogError(@"Cannot open keys (incorrect password?)");
        [self freeKeys];
    }
    return ret;
}

- (void) debugDumpKeysToFiles
{
	NSString *qliqId = [UserSessionService currentUserSession].sipAccountSettings.username;
	NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *userDir = [documentsDirectory stringByAppendingFormat:@"/%@", qliqId];
    if(![fileManager fileExistsAtPath:userDir])
    {
        [fileManager createDirectoryAtPath:userDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *filePath = [userDir stringByAppendingPathComponent:@"private_key_dump.txt"];
    NSError *error = nil;
    BOOL succeeded = [self.privateKeyString writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (!succeeded) {
        DDLogError(@"Cannot dump private key to file: %@", filePath);
        return;
    } else {
        DDLogSupport(@"Dumped private key to file: %@", filePath);
    }

    filePath = [userDir stringByAppendingPathComponent:@"public_key_dump.txt"];
    succeeded = [self.publicKeyString writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (!succeeded) {
        DDLogError(@"Cannot dump public key to file: %@", filePath);
        return;
    } else {
        DDLogSupport(@"Dumped public key to file: %@", filePath);
    }
}

- (void) deleteKeysForUser: (NSString *)userName
{
    [self freeKeys];
    self.currentUserName = nil;
    
    [self deleteKeysInKeychainForUsername:userName];
}

- (void) setDefaultPaths: (NSString *)userName
{
	NSString *subDir = [NSString stringWithFormat: @"keys/%@", userName]; 
	NSString *path = [[NSFileManager defaultManager] applicationSupportDirectoryWithSubDir: subDir];
	privateKeyPath = [NSString stringWithFormat: @"%@/private_key", path]; 
	publicKeyPath = [NSString stringWithFormat: @"%@/public_key", path]; 	
}

static NSString *readWholeFile(FILE *fp)
{
	fseek(fp, 0, SEEK_END);
	long size = ftell(fp);
	fseek(fp, 0, SEEK_SET);
	
	char *buffer = malloc(size + 1);
	buffer[size] = '\0';
	fread(buffer, size, 1, fp);
	
	NSString *ret = [NSString stringWithUTF8String: buffer];
	free(buffer);
	return ret;
}

- (BOOL) readKeysFromDisk: (NSString *)password
{
	BOOL ret = NO;
	privateKey = NULL;
	publicKey = NULL;
	
	FILE *pkey_fp = fopen([privateKeyPath UTF8String], "r");
	if (pkey_fp) {
		PEM_read_PrivateKey(pkey_fp, (EVP_PKEY **)&privateKey, NULL, (void *)[password UTF8String]);
		self.privateKeyString = readWholeFile(pkey_fp);
		fclose(pkey_fp);
		
		FILE *pubkey_fp = fopen([publicKeyPath UTF8String], "r");
		if (pubkey_fp) {
			PEM_read_PUBKEY(pubkey_fp, (EVP_PKEY **)&publicKey, NULL, 0);
			self.publicKeyString = readWholeFile(pubkey_fp);
			fclose(pubkey_fp);
		} else
        {
			DDLogSupport(@"Cannot open file: %@", publicKeyPath);
        }
		
	} else
		DDLogSupport(@"Cannot open file: %@", privateKeyPath);
	
	ret = (privateKey != NULL) && (publicKey != NULL);
    if (ret) {
        [QxPlatfromIOS setKeyPair:publicKey publicKeyString:publicKeyString privateKey:privateKey];
    } else {
        [QxPlatfromIOS setKeyPair:nil publicKeyString:@"" privateKey:nil];
    }
	return ret;	
}

- (BOOL) readKeysFromKeychain: (NSString *)username withPassword:(NSString *)password
{
    [self freeKeys];
    
	NSError *error = nil;
	NSString *privKeyString = [QliqKeychainUtils getItemForKey: [NSString stringWithFormat: @"%@-%@", KS_KEY_PRIVATE_KEY, username] error: &error];
	NSString *pubKeyString = [QliqKeychainUtils getItemForKey: [NSString stringWithFormat: @"%@-%@", KS_KEY_PUBLIC_KEY, username] error: &error];
	
	BOOL ret = NO;
	
	if ([privKeyString length] > 0 && [pubKeyString length] > 0)
	{
		privateKey = (EVP_PKEY *) [Crypto readKeyFromString: privKeyString type: PrivateKey withPassword: password];
		publicKey = (EVP_PKEY *)[Crypto readKeyFromString: pubKeyString type: PublicKey withPassword: nil];
		ret = (privateKey != NULL && publicKey != NULL);
		if (ret) {
            int keyBitSize = RSA_size(((EVP_PKEY *)publicKey)->pkey.rsa) * 8;
            if (keyBitSize < KEY_BIT_SIZE) {
                [self freeKeys];
                ret = NO;
                DDLogError(@"Refusing old keys because of insufficient size");
            } else {
                self.privateKeyString = privKeyString;
                self.publicKeyString = pubKeyString;
                [QxPlatfromIOS setKeyPair:publicKey publicKeyString:publicKeyString privateKey:privateKey];
            }
		}
	}
	return ret;
}

- (void) generateKeys: (NSString *)password
{
    DDLogSupport(@"Generating new keys");
    [self freeKeys];
    
	X509 *x509 = NULL;
	mkcert2(&x509, (EVP_PKEY **)&privateKey, KEY_BIT_SIZE, 0, 365);
	publicKey = X509_get_pubkey(x509);
	X509_free(x509);
	//	[self writeKeys: password];
	//[self readKeys: password];
	

	self.privateKeyString = [Crypto keyToString: privateKey type: PrivateKey withPassword: password];
	self.publicKeyString = [Crypto keyToString: publicKey type: PublicKey withPassword: nil];
}

- (void) writeKeys: (NSString *)password
{
	FILE *pkey_fp = fopen([privateKeyPath UTF8String], "w");
	FILE *pubkey_fp = fopen([publicKeyPath UTF8String], "w");
	
	if (pkey_fp) {
		PEM_write_PrivateKey(pkey_fp, (EVP_PKEY *)privateKey, EVP_des_ede3_cbc(), NULL, 0, NULL, (void *)[password UTF8String]);
		fclose(pkey_fp);
	} else
		DDLogSupport(@"Cannot open file for writing: %@", privateKeyPath);
	
	if (pubkey_fp) {
		PEM_write_PUBKEY(pubkey_fp, (EVP_PKEY *)publicKey);
		fclose(pubkey_fp);
	} else
		DDLogSupport(@"Cannot open file for writing: %@", publicKeyPath);
}

#define qMin(a, b) (a < b ? a : b)

+ (NSString *) encryptToBase64: (NSString *)plainData: (NSString *)pubKeyString
{
    EVP_PKEY *pubKey = (EVP_PKEY *) [Crypto readKeyFromString: pubKeyString: PublicKey];
    if (pubKey == NULL)
		return nil;
	
	const int len = RSA_size(pubKey->pkey.rsa);
	const int blockLen = len - 12; // space for RSA_PKCS1_PADDING
	unsigned char *buffer = malloc(len);
	
	BIO *mem = BIO_new(BIO_s_mem());
	// Push on a Base64 filter so that writing to the buffer encodes the data
	BIO *b64 = BIO_new(BIO_f_base64());
	mem = BIO_push(b64, mem);
	
	const char *latinPlainData = [plainData UTF8String];
	int totalBytes = [plainData length];
	int pos = 0;
	
	while (pos < totalBytes) {
		int bytesToEnc = qMin(blockLen, totalBytes - pos);
		int encLen = RSA_public_encrypt (bytesToEnc, (const unsigned char *)latinPlainData + pos, buffer, pubKey->pkey.rsa, RSA_PKCS1_PADDING);
		if (encLen == -1) {
            // We need to clear the OpenSSL error so it is not propagated to pjproject or elsewhere
            int errLevel = 0;
            unsigned long errCode = ERR_get_error();
            while (errCode != 0) {
                DDLogError(@"Error in RSA_public_encrypt: %lu, level %d", errCode, errLevel);
                errCode = ERR_get_error();
                errLevel++;
            }
			break;
		}
		BIO_write(mem, buffer, encLen);
		pos += bytesToEnc;
	}
	(void)BIO_flush(mem);
	free(buffer);
	EVP_PKEY_free(pubKey);
	
	char *base64Pointer;
	long base64Length = BIO_get_mem_data(mem, &base64Pointer);
	NSString *base64String = [[[NSString alloc] initWithBytes:base64Pointer
                                                      length: base64Length
                                                    encoding:NSUTF8StringEncoding] autorelease];
	BIO_free_all(mem);
	return base64String;
}

- (NSString *) decryptFromBase64: (NSString *) encryptedBase64 wasOk:(BOOL *)ok
{
    NSString *ret = nil;

    // We lock this section because the private key can be freed by 'login_credentials' changed
    // notification and SIP thread can be testing if a message can be decrypted at the same time
    @synchronized (self) {
        if (privateKey != nil) {
            ret = [Crypto decryptFromBase64:encryptedBase64 wasOk:ok privateKey:(EVP_PKEY *)privateKey];
            *ok = (encryptedBase64.length > 0) ? (ret.length > 0) : ret != nil;
        } else {
            DDLogSupport(@"Private Key is NIL. Skipping Decryption");
            ret = nil;
            *ok = NO;
        }
    }
    return ret;
}

+ (NSString *) decryptFromBase64: (NSString *) encryptedBase64 privateKey:(NSString *)privateKey password:(NSString *)password wasOk:(BOOL *)ok
{
    NSString *ret = nil;
    EVP_PKEY *key = (EVP_PKEY *) [Crypto readKeyFromString:privateKey type:PrivateKey withPassword:password];
    if (key != NULL)
    {
        ret = [Crypto decryptFromBase64:encryptedBase64 wasOk:ok privateKey:key];
        EVP_PKEY_free(key);
        if (ok)
            *ok = YES;
    }
    else
    {
        if (ok)
            *ok = NO;
    }
    return ret;
}

+ (NSString *) decryptFromBase64: (NSString *) encryptedBase64 wasOk:(BOOL *)ok privateKey:(EVP_PKEY *)privKey
{
	
	BIO *mem = BIO_new_mem_buf((void *)[encryptedBase64 UTF8String], [encryptedBase64 lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
	BIO *b64 = BIO_new(BIO_f_base64());
	mem = BIO_push(b64, mem);
	
	NSMutableData *encryptedData = [NSMutableData data];
	char inbuf[512];
	int inlen;
	while ((inlen = BIO_read(mem, inbuf, sizeof(inbuf))) > 0) {
		[encryptedData appendBytes: inbuf
							length: inlen];
	}
	
	BIO_free_all(mem);
	
	NSMutableData *decryptedData = [NSMutableData data];
	
	const int len = RSA_size(privKey->pkey.rsa);
	unsigned char *buffer = malloc(len+1);
	
	const unsigned char *encryptedBytes = [encryptedData bytes];
	int totalBytes = [encryptedData length];
	int pos = 0;
	int totalDecryptedLen = 0;
    
    if (ok)
        *ok = YES;
	
	while (pos < totalBytes) {
		int bytesToDecrypt = qMin(len, totalBytes - pos);
		int decrLen = RSA_private_decrypt(bytesToDecrypt, encryptedBytes + pos, buffer, privKey->pkey.rsa, RSA_PKCS1_PADDING);
		if (decrLen == -1) {
            if (ok)
                *ok = NO;
            
            // We need to clear the OpenSSL error so it is not propagated to pjproject or elsewhere
            int errLevel = 0;
            unsigned long errCode = ERR_get_error();
            while (errCode != 0) {
                DDLogError(@"Error in RSA_private_decrypt: %lu, level %d", errCode, errLevel);
                errCode = ERR_get_error();
                errLevel++;
            }
			break;
		}
		
		buffer[decrLen] = '\0';
		[decryptedData appendBytes: buffer
						length: decrLen];
		totalDecryptedLen += decrLen;
		pos += bytesToDecrypt;
	}

	free(buffer);

	const char *decryptedBytes = (const char *) [decryptedData bytes];
	NSString *decrypted = [[[NSString alloc] initWithBytes:decryptedBytes
                                                   length:totalDecryptedLen
                                                  encoding:NSUTF8StringEncoding] autorelease];
	return decrypted;
}

- (void) storeKeysInKeychainForUsername: (NSString *)username
{
	NSError *error = nil;
	[QliqKeychainUtils storeItemForKey:[NSString stringWithFormat:@"%@-%@", KS_KEY_PRIVATE_KEY, username] andValue:privateKeyString error:&error];
	[QliqKeychainUtils storeItemForKey:[NSString stringWithFormat:@"%@-%@", KS_KEY_PUBLIC_KEY, username] andValue:publicKeyString error:&error];	
}

- (void) deleteKeysInKeychainForUsername: (NSString *)username
{
	NSError *error = nil;
	[QliqKeychainUtils deleteItemForKey:[NSString stringWithFormat:@"%@-%@", KS_KEY_PRIVATE_KEY, username] error:&error];
	[QliqKeychainUtils deleteItemForKey:[NSString stringWithFormat:@"%@-%@", KS_KEY_PUBLIC_KEY, username] error:&error];
}

- (void) freeKeys
{
    // We lock this section because this can be executed by 'login_credentials' changed
    // notification and SIP thread can be testing if a message can be decrypted at the same time
    @synchronized (self) {
        EVP_PKEY_free((EVP_PKEY *)privateKey);
        EVP_PKEY_free((EVP_PKEY *)publicKey);
        privateKey = publicKey = NULL;
        self.publicKeyString = nil;
        self.privateKeyString = nil;
        [QxPlatfromIOS setKeyPair:nil publicKeyString:@"" privateKey:nil];
    }
}

+ (BOOL) isValidPublicKey: (NSString *)pubKeyString
{
    EVP_PKEY *pubKey = (EVP_PKEY *) [Crypto readKeyFromString: pubKeyString: PublicKey];
    BOOL ret = (pubKey != NULL);
    EVP_PKEY_free(pubKey);
    return ret;
}

+ (BOOL) isValidPrivateKey: (NSString *)keyString withPassword:(NSString *)password
{
    EVP_PKEY *key = (EVP_PKEY *) [Crypto readKeyFromString:keyString type:PrivateKey withPassword:password];
    BOOL ret = (key != NULL);
    EVP_PKEY_free(key);
    return ret;
}

+ (NSString *) privateKeyRepassword: (NSString *)keyString oldPassword:(NSString *)oldPassword newPassword:(NSString *)newPassword
{
    NSString *ret = nil;
    EVP_PKEY *key = [Crypto readKeyFromString:keyString type:PrivateKey withPassword:oldPassword];
    if (key != nil) {
        BIO *mem = BIO_new(BIO_s_mem());
        PEM_write_bio_PrivateKey(mem, key, EVP_des_ede3_cbc(), NULL, 0, NULL, (void *)[newPassword UTF8String]);
        BIO_flush(mem);
        char *pemPointer;
        long pemLength = BIO_get_mem_data(mem, &pemPointer);
        ret = [[[NSString alloc] initWithBytes: pemPointer
                                        length: pemLength
                                      encoding: NSUTF8StringEncoding] autorelease];
        BIO_free_all(mem);
        EVP_PKEY_free(key);

    } else {
        DDLogError(@"Cannot open private key (wrong password?)");
    }
    return ret;
}

+ (void *) readKeyFromString: (NSString *)pubKeyString: (KeyType)type
{
	return [self readKeyFromString: pubKeyString type: type withPassword: nil];
}

+ (void *) readKeyFromString: (NSString *)keyString type:(KeyType)type withPassword:(NSString*)password
{
	BIO *bio = BIO_new_mem_buf((void *)[keyString UTF8String], [keyString length]);
	EVP_PKEY *key = nil;
	
	void *pass = 0;
	if (password != nil)
		pass = (void *)[password UTF8String];
		
    if ([keyString hasPrefix:RSA_KEY_HEADER_PREFIX]) {
        RSA *rsa = nil;
        if (type == PrivateKey) {
            key = PEM_read_bio_RSAPrivateKey(bio, &rsa, NULL, pass);
        } else {
            key = PEM_read_bio_RSAPublicKey(bio, &rsa, NULL, pass);
        }
        
        if (rsa) {
            key = EVP_PKEY_new();
            if (key)
                EVP_PKEY_set1_RSA(key, rsa);
            RSA_free(rsa);
        }
        
    } else {
        if (type == PrivateKey)
            key = PEM_read_bio_PrivateKey(bio, NULL, NULL, pass);
        else
            key = PEM_read_bio_PUBKEY(bio, NULL, NULL, pass);
    }
    
	BIO_free(bio);
	return key;
}

+ (NSString *) keyToString: (void *)key type:(KeyType)type withPassword:(NSString*)password
{
	BIO *bio = BIO_new(BIO_s_mem());
	
	void *pass = 0;
	if (password != nil)
		pass = (void *)[password UTF8String];
	
	if (type == PrivateKey)
		PEM_write_bio_PrivateKey(bio, (EVP_PKEY *)key, EVP_des_ede3_cbc(), NULL, 0, NULL, pass);
	else
		PEM_write_bio_PUBKEY(bio, (EVP_PKEY *)key);
	
	char *pemPointer;
	long pemLength = BIO_get_mem_data(bio, &pemPointer);
//	NSString *pemString = [NSString stringWithCString: pemPointer
//												  length: pemLength];	

	NSString *pemString = [[[NSString alloc] initWithBytes:pemPointer
                                                    length: pemLength
                                                  encoding:NSUTF8StringEncoding] autorelease];
	
	BIO_free_all(bio);
	return pemString;
}

@end

static void callback(int p, int n, void *arg)
{
    char c='B';
	
    if (p == 0) c='.';
    if (p == 1) c='+';
    if (p == 2) c='*';
    if (p == 3) c='\n';
    fputc(c,stderr);
}

/* Add extension using V3 code: we can set the config file as NULL
 * because we wont reference any other sections.
 */

static int add_ext(X509 *cert, int nid, char *value)
{
    X509_EXTENSION *ex;
    X509V3_CTX ctx;
    /* This sets the 'context' of the extensions. */
    /* No configuration database */
    X509V3_set_ctx_nodb(&ctx);
    /* Issuer and subject certs: both the target since it is self signed,
     * no request and no CRL
     */
    X509V3_set_ctx(&ctx, cert, cert, NULL, NULL, 0);
    ex = X509V3_EXT_conf_nid(NULL, &ctx, nid, value);
    if (!ex)
        return 0;
	
    X509_add_ext(cert,ex,-1);
    X509_EXTENSION_free(ex);
    return 1;
}

static int mkcert2(X509 **x509p, EVP_PKEY **pkeyp, int bits, int serial, int days)
{
    X509 *x;
    EVP_PKEY *pk;
    RSA *rsa;
    X509_NAME *name=NULL;
	
    if ((pkeyp == NULL) || (*pkeyp == NULL))
    {
        if ((pk=EVP_PKEY_new()) == NULL)
        {
            abort();
            return(0);
        }
    }
    else
        pk= *pkeyp;
	
    if ((x509p == NULL) || (*x509p == NULL))
    {
        if ((x=X509_new()) == NULL)
            goto err;
    }
    else
        x= *x509p;
	
    rsa=RSA_generate_key(bits,RSA_F4,callback,NULL);
	if (!EVP_PKEY_assign_RSA(pk,rsa))
    {
        abort();
        goto err;
    }
    rsa=NULL;
	
    X509_set_version(x,2);
    ASN1_INTEGER_set(X509_get_serialNumber(x),serial);
    X509_gmtime_adj(X509_get_notBefore(x),0);
    X509_gmtime_adj(X509_get_notAfter(x),(long)60*60*24*days);
    X509_set_pubkey(x,pk);
	
    name=X509_get_subject_name(x);
	
    /* This function creates and adds the entry, working out the
     * correct string type and performing checks on its length.
     * Normally we'd check the return value for errors...
     */
	X509_NAME_add_entry_by_txt(name,"O",
							   MBSTRING_ASC, (const unsigned char *)"qliqSoft Inc", -1, -1, 0);
    X509_NAME_add_entry_by_txt(name,"L",
							   MBSTRING_ASC, (const unsigned char *)"Richardson", -1, -1, 0);
    X509_NAME_add_entry_by_txt(name,"S",
							   MBSTRING_ASC, (const unsigned char *)"TX", -1, -1, 0);
    X509_NAME_add_entry_by_txt(name,"C",
							   MBSTRING_ASC, (const unsigned char *)"USA", -1, -1, 0);
    X509_NAME_add_entry_by_txt(name,"CN",
							   MBSTRING_ASC, (const unsigned char *)"qliqsoft.com", -1, -1, 0);
	
	/* Its self signed so set the issuer name to be the same as the
     * subject.
     */
    X509_set_issuer_name(x,name);
	
    /* Add various extensions: standard extensions */
    add_ext(x, NID_basic_constraints, "critical,CA:TRUE");
    add_ext(x, NID_key_usage, "critical,keyCertSign,cRLSign");
	
    add_ext(x, NID_subject_key_identifier, "hash");
	
#ifdef CUSTOM_EXT
    /* Maybe even add our own extension based on existing */
    {
        int nid;
        nid = OBJ_create("1.2.3.4", "MyAlias", "My Test Alias Extension");
        X509V3_EXT_add_alias(nid, NID_netscape_comment);
        add_ext(x, nid, "example comment alias");
    }
#endif
	
	
    if (!X509_sign(x,pk,EVP_md5()))
        goto err;
	
	if (x509p != NULL)
		*x509p=x;

	if (pkeyp != NULL)
		*pkeyp=pk;
	
    return(1);
err:
    return(0);
}



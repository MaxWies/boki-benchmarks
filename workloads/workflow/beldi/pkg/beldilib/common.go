package beldilib

import (
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"

	// "github.com/aws/aws-sdk-go/service/lambda"
	"os"
	"strconv"
)

var sess = session.Must(session.NewSessionWithOptions(session.Options{
	SharedConfigState: session.SharedConfigEnable,
}))

var DBClient = dynamodb.New(sess, &aws.Config{
	Endpoint:                      aws.String("DYNAMODB_ENDPOINT"),
	Region:                        aws.String("eu-west-1"),
	CredentialsChainVerboseErrors: aws.Bool(true),
})

// var LambdaClient = lambda.New(sess)

//var url = "http://133.130.115.39:8000"
//var DBClient = dynamodb.New(sess, &aws.Config{Endpoint: aws.String(url),
//	Region:                        aws.String("us-east-1"),
//	CredentialsChainVerboseErrors: aws.Bool(true)})

var DLOGSIZE = "1000"

func GLOGSIZE() int {
	r, _ := strconv.Atoi(DLOGSIZE)
	return r
}

// var T = int64(60)
var T = int64(30)

var TYPE = "BELDI"

func CHECK(err error) {
	if err != nil {
		panic(err)
	}
}

var kTablePrefix = os.Getenv("TABLE_PREFIX")

package cayonlib

import (
	"os"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
)

var sess = session.Must(session.NewSessionWithOptions(session.Options{
	SharedConfigState: session.SharedConfigEnable,
}))

var DBClient = dynamodb.New(sess, &aws.Config{
	Endpoint:                      aws.String(os.Getenv("DYNAMODB_ENDPOINT")),
	Region:                        aws.String("eu-west-1"),
	CredentialsChainVerboseErrors: aws.Bool(true),
})

var T = int64(60)

var TYPE = "BELDI"

func CHECK(err error) {
	if err != nil {
		panic(err)
	}
}

var kTablePrefix = os.Getenv("TABLE_PREFIX")

package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/ssh"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/require"
)

func createTerraformOptions(t *testing.T, testDir string) *terraform.Options {
	// A unique ID we can use to namespace resources so we don't clash with anything already in the AWS account or
	// tests running in parallel

	uniqueID := random.UniqueId()
	projectId := fmt.Sprintf("terraform-test-project-%s", uniqueID)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: testDir,
		Vars: map[string]interface{}{
			"project_id":           projectId,
			"region":               "us-central1",
			"zone":                 "us-central1-a",
			"machine_type":         "e2-standard-4",
			"bitcoin_rpc_user":     "test-user",
			"bitcoin_rpc_password": "test-password",
			"index_start_height":   0,
			"network":              "testnet",
		},
	})

	return terraformOptions
}
func TestIndexerDeployment(t *testing.T) {
	t.Parallel()

	testDir := test_structure.CopyTerraformFolderToTemp(t, "../..", "")

	defer test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, testDir)
		terraform.Destroy(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "setup", func() {
		terraformOptions := createTerraformOptions(t, testDir)
		test_structure.SaveTerraformOptions(t, testDir, terraformOptions)
		terraform.InitAndApply(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "validate", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, testDir)

		instanceIP := terraform.Output(t, terraformOptions, "instance_ip")
		bitcoinNetwork := terraform.Output(t, terraformOptions, "bitcoin_network")

		// Validate instance IP
		require.NotEmpty(t, instanceIP, "Instance IP should not be empty")

		// Validate Bitcoin network
		require.Contains(t, []string{"mainnet", "testnet", "regtest"}, bitcoinNetwork, "Bitcoin network should be mainnet, testnet, or regtest")

	})
}

func TestOrdProcessRunning(t *testing.T) {
	t.Parallel()

	exampleDir := test_structure.CopyTerraformFolderToTemp(t, "../..", "")

	test_structure.RunTestStage(t, "setup", func() {
		terraformOptions := createTerraformOptions(t, exampleDir)
		test_structure.SaveTerraformOptions(t, exampleDir, terraformOptions)
		terraform.InitAndApply(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "validate", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, exampleDir)
		instanceIP := terraform.Output(t, terraformOptions, "instance_ip")

		// SSH into the instance
		_, err := ssh.NewSshAgent(t, "", "")
		require.NoError(t, err, "Error creating SSH agent")

		host := ssh.Host{
			Hostname:    instanceIP,
			SshUserName: "ubuntu", // Adjust if you're using a different username
			SshAgent:    true,
		}

		// Check if ord process is running
		output, err := ssh.CheckSshCommandE(t, host, "pgrep -f ord")
		require.NoError(t, err, "Error checking ord process")
		require.NotEmpty(t, output, "ord process should be running")

		// Check ord logs
		output, err = ssh.CheckSshCommandE(t, host, "tail -n 10 /var/log/ord.log")
		require.NoError(t, err, "Error checking ord logs")
		require.Contains(t, output, "ord started", "ord logs should indicate successful start")

		// Check the API endpoint
		// curl -s -H "Accept: application/json" 'http://0.0.0.0:80/inscriptions'

		output, err = ssh.CheckSshCommandE(t, host, "curl -s -H \"Accept: application/json\" 'http://0.0.0.0:80/inscriptions'")

		require.NoError(t, err, "Error checking ord API endpoint")
		require.Contains(t, output, "ord is running", "ord API endpoint should return ord status")

	})

	defer test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, exampleDir)
		terraform.Destroy(t, terraformOptions)
	})
}

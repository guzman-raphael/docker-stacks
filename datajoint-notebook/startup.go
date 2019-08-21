package main

import (
	"strings"
	"io/ioutil"
	"os"
	// "os/exec"
	"fmt"
)

func main() {
	var old_user, new_user string = os.Args[1], os.Args[2]

	pass_byte, _ := ioutil.ReadFile("/etc/passwd")
	pass_str := string(pass_byte)
	pass_str = strings.Replace(
		pass_str, old_user, new_user, -1)
	pass_file, _ := os.Create("/etc/passwd")
	pass_file.WriteString(pass_str)
	pass_file.Close()


	// // out, err := exec.Command("pwd").Output()
	// out, err := exec.Command("id").Output()
	// // out, err := exec.Command("mv", "/home/" + old_user,"/home/" + new_user).Output()

    // // if there is an error with our execution
    // // handle it here
    // if err != nil {
    //     fmt.Printf("%s", err)
    // }
    // // as the out variable defined above is of type []byte we need to convert
    // // this to a string or else we will see garbage printed out in our console
    // // this is how we convert it to a string
    // fmt.Println("Command Successfully Executed")
    // output := string(out[:])
    // fmt.Println(output)


	err := os.Rename("/home/" + old_user, "/home/" + new_user) // rename directory

	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	// group_byte, _ := ioutil.ReadFile("/etc/group")
	// group_str := string(group_byte)
	// group_str = strings.Replace(
	// 	group_str, user + ":x:3000", user + ":x:" + uid, -1)
	// group_file, _ := os.Create("/etc/group")
	// group_file.WriteString(group_str)
	// group_file.Close()

	// uid_int, _ := strconv.Atoi(uid)
	// gid_int, _ := strconv.Atoi(gid)
	// os.Chown(home, uid_int, gid_int)
	// os.Chown(home + "/.local", uid_int, gid_int)
	// os.Chown(home + "/activate.ini", uid_int, gid_int)
}

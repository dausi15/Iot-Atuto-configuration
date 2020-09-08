/*
 * Copyright (c) 2013 IBM Corp.
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *    Seth Hoenig
 *    Allan Stockdill-Mander
 *    Mike Robertson
 */

//https://github.com/eclipse/paho.mqtt.golang/blob/master/cmd/stdoutsub/main.go

 package main

 import (
	 "crypto/tls"
	 "flag"
	 "fmt"
	 //"log"
	 "os"
	 "os/signal"
	 "strconv"
	 "syscall"
	 "time"
	 "net/url"
	 "log"
	 "net"

	 "google.golang.org/grpc"
	 "github.com/dausi15/Iot-Atuto-configuration/iotserver/goclient/chat"

	 client "github.com/influxdata/influxdb1-client"
	 MQTT "github.com/eclipse/paho.mqtt.golang"
 )


func BytesToString(data []byte) string {
	return string(data[:])
}
 
 func onMessageReceived(client MQTT.Client, message MQTT.Message) {
	 now := time.Now().String()
	 fmt.Printf("Received message on topic: %s\nMessage: %s\nAt: %s\n", message.Topic(), message.Payload(), now)
	 ExampleClient_Write(now, message.Topic(), BytesToString(message.Payload()))
 }

 func ExampleClient_Write(val string, col string, shape string) {
	host, err := url.Parse(fmt.Sprintf("http://%s:%d", "localhost", 8086))
	if err != nil {
		log.Fatal(err)
	}
	con, err := client.NewClient(client.Config{URL: *host})
	if err != nil {
		log.Fatal(err)
	}
	git config --global url."https://github.com/".insteadOf "git@github.com"
	var (
		pts = make([]client.Point, 1)	
	)
	fmt.Printf("Writing: \n%s\n%s\n%s", val, col, shape)

		pts[0] = client.Point{
			Measurement: "registration",
			Tags: map[string]string{
				"topic": col,
				"message": shape,
			},
			Fields: map[string]interface{}{
				"value": val,
			},
			Time:      time.Now(),
			Precision: "s",
		}
	

	bps := client.BatchPoints{
		Points:          pts,
		Database:        "mydb",
		RetentionPolicy: "autogen",
	}
	_, err = con.Write(bps)
	if err != nil {
		log.Fatal(err)
	}
}
 


 func main() {

	lis, err := net.Listen("tcp", ":9000")
	if err != nil {
		log.Fatalf("Failed to listen on port 9000: %v", err)
	}

	grpcServer := grpc.NewServer()

	if err := grpcServer.Serve(lis); err != nil {
		log.Fatalf("Failed to server gRPC server over port 9000: %v", err)
	}
	 //MQTT.DEBUG = log.New(os.Stdout, "", 0)
	 //MQTT.ERROR = log.New(os.Stdout, "", 0)
	 c := make(chan os.Signal, 1)
	 signal.Notify(c, os.Interrupt, syscall.SIGTERM)
 
	 hostname, _ := os.Hostname()
 
	 server := flag.String("server", "tcp://localhost:1883", "The full url of the MQTT server to connect to ex: tcp://127.0.0.1:1883")
	 topic := flag.String("topic", "#", "Topic to subscribe to")
	 qos := flag.Int("qos", 0, "The QoS to subscribe to messages at")
	 clientid := flag.String("clientid", hostname+strconv.Itoa(time.Now().Second()), "A clientid for the connection")
	 username := flag.String("username", "", "A username to authenticate to the MQTT server")
	 password := flag.String("password", "", "Password to match username")
	 flag.Parse()
 
	 connOpts := MQTT.NewClientOptions().AddBroker(*server).SetClientID(*clientid).SetCleanSession(true)
	 if *username != "" {
		 connOpts.SetUsername(*username)
		 if *password != "" {
			 connOpts.SetPassword(*password)
		 }
	 }
	 tlsConfig := &tls.Config{InsecureSkipVerify: true, ClientAuth: tls.NoClientCert}
	 connOpts.SetTLSConfig(tlsConfig)
 
	 connOpts.OnConnect = func(c MQTT.Client) {
		 if token := c.Subscribe(*topic, byte(*qos), onMessageReceived); token.Wait() && token.Error() != nil {
			 panic(token.Error())
		 }
	 }
 
	 client := MQTT.NewClient(connOpts)
	 if token := client.Connect(); token.Wait() && token.Error() != nil {
		 panic(token.Error())
	 } else {
		 fmt.Printf("Connected to %s\n", *server)
	 }
 
	 <-c
 }

//Influx start: use mydb.autogen
 //curl -G 'http://localhost:8086/query?pretty=true' --data-urlencode "db=mydb" --data-urlencode "q=SELECT * FROM registration"

 //Publish data: mosquitto_pub -h localhost -m "test message; start=1248564456" -t "go-mqtt/sample"


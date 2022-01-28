// Code generated by oapi-codegen. DO NOT EDIT.
// Package alerts provides primitives to interact with the openapi HTTP API.
//
// Code generated by github.com/deepmap/oapi-codegen version v1.7.0 DO NOT EDIT.
package alerts

import (
	"time"
)

// Defines values for AlertSeverity.
const (
	AlertSeverityCRITICAL AlertSeverity = "CRITICAL"

	AlertSeverityINFO AlertSeverity = "INFO"

	AlertSeverityWARNING AlertSeverity = "WARNING"
)

// A set of alerts for a configpath
type AetherAlerts []Alert

// Alert defines model for Alert.
type Alert struct {

	// An auto-generated UUID value to identify the alert
	AlertId string `json:"alert-id" yaml:"alert-id"`

	// The time the alert was cleared
	ClearedAt  *time.Time `json:"cleared-at,omitempty" yaml:"cleared-at,omitempty"`
	Configpath string     `json:"configpath" yaml:"configpath"`

	// A description of what error condition is being represented
	Message string `json:"message" yaml:"message"`

	// The time the alert was originally raised
	RaisedAt time.Time `json:"raised-at" yaml:"raised-at"`

	// The severity of the Alert
	Severity AlertSeverity `json:"severity" yaml:"severity"`
}

// The severity of the Alert
type AlertSeverity string

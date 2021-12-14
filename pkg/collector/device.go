// SPDX-FileCopyrightText: 2021-present Open Networking Foundation <info@opennetworking.org>
//
// SPDX-License-Identifier: LicenseRef-ONF-Member-Only-1.0

package collector

import (
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"math/rand"
	"time"
)

func (d *Device) collect(period time.Duration, site string) {
	log.Infof("Starting collector for Device %s", d.SerialNumber)
	go func() {
		for {
			count := float64(rand.Intn(10))
			if d.Sim != nil {
				if count != 5 {
					deviceConnectedStatus.WithLabelValues("Active", site, *d.Sim).Set(1)
				} else {
					deviceConnectedStatus.WithLabelValues("Active", site, *d.Sim).Set(0)
				}
			}
			time.Sleep(period * 3)
		}
	}()

	go func() {
			time.Sleep(period*2)
			if d.Sim != nil {
				deviceConnectionEventCore.WithLabelValues("some core event", "some colour", site, *d.Sim).Set(1)
			}
	}()

	go func() {
		time.Sleep(period*4)
		if d.Sim != nil {
			deviceConnectionEventRan.WithLabelValues("some ran event", site, *d.Sim).Set(1)
		}
	}()

	go func() {
		time.Sleep(period*6)
		if d.Sim != nil {
			deviceConnectionEventFabric.WithLabelValues("some fabric event", site, *d.Sim).Set(1)
		}
	}()
}

var (
	deviceConnectedStatus = promauto.NewGaugeVec(prometheus.GaugeOpts{
		Name: "device_connected_status",
		Help: "Device Status",
	}, []string{"device_status", "site", "iccid"})

	deviceConnectionEventCore = promauto.NewGaugeVec(prometheus.GaugeOpts{
		Name: "device_connection_event_core",
		Help: "Device Connection Event Core",
	}, []string{"msg", "colour", "site", "iccid"})

	deviceConnectionEventRan = promauto.NewGaugeVec(prometheus.GaugeOpts{
		Name: "device_connection_event_ran",
		Help: "Device Connection Event Ran",
	}, []string{"msg", "site", "iccid"})

	deviceConnectionEventFabric = promauto.NewGaugeVec(prometheus.GaugeOpts{
		Name: "device_connection_event_fabric",
		Help: "Device Connection Event Fabric",
	}, []string{"msg", "site", "iccid"})
)

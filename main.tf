variable "path" {
    default="C:/Users/THLOHITH/Desktop/terraformdemo/demo1/analysis"
}
provider "google" {
  credentials="${file("${var.path}/projectvpcpoc-2-99558a5165ac.json")}"
  project     = "projectvpcpoc-2"
  region      = "us-central1"
}
 
// resource
resource "google_compute_instance" "instance1" {
    name = "instance-monitoring"
    machine_type = "n1-standard-1"
    zone = "us-central1-a"
 
    boot_disk {
      initialize_params {
        image = "debian-cloud/debian-9"
      }
    }
 
    network_interface {
      network = "default"
      subnetwork = "default"
 
      access_config {
         // Ephemeral IP
      }
    }
    tags = [ "http-server" ]
 
}

// Creating dashboard
resource "google_monitoring_dashboard" "dashboard1" {
  dashboard_json = <<EOF
{
  "displayName": "Cloud Monitoring Dashboard1",
  "gridLayout": {
    "columns": "2",
    "widgets": [
      {
        "title": "CPU Utilization",
        "xyChart": {
          "dataSets": [{
            "timeSeriesQuery": {
              "timeSeriesFilter": {
                "filter": "resource.type=gce_instance AND metric.type=\"compute.googleapis.com/instance/cpu/utilization\"",
                "aggregation": {
                    "perSeriesAligner": "ALIGN_MEAN"
                  
                }
              },
              "unitOverride": "1"
            },
            "plotType": "LINE"
          }],
          "timeshiftDuration": "0s",
          "yAxis": {
            "label": "y1Axis",
            "scale": "LINEAR"
          }
        }
      },
      {
        "title": "Disk Bytes rate",
        "xyChart": {
          "dataSets": [{
            "timeSeriesQuery": {
              "timeSeriesFilter": {
                "filter": "resource.type=gce_instance AND metric.type=\"compute.googleapis.com/instance/disk/read_bytes_count\"",
                "aggregation": {
                  "perSeriesAligner": "ALIGN_MEAN"
                }
              },
              "unitOverride": "1"
            },
            "plotType": "STACKED_AREA"
          }],
          "timeshiftDuration": "0s",
          "yAxis": {
            "label": "y1Axis",
            "scale": "LINEAR"
          }
        }
      }
    ]
  }
}

EOF
}
resource "google_monitoring_alert_policy" "alert_policy" {
  display_name = "My AlertingPolicy"
  combiner     = "OR"
  conditions {
    display_name = "test condition for cpu utilization"
    condition_threshold {
      filter     = "resource.type=gce_instance AND metric.type=\"compute.googleapis.com/instance/cpu/utilization\""
      duration   = "60s"
      comparison = "COMPARISON_GT"
      threshold_value = "1.0"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }

  }
  conditions {
    display_name = "test condition for disk byte reads"
    condition_threshold {
      filter     = "resource.type=gce_instance AND metric.type=\"compute.googleapis.com/instance/disk/read_bytes_count\""
      duration   = "60s"
      comparison = "COMPARISON_GT"
      threshold_value = "1.0"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }

  }
notification_channels=google_monitoring_notification_channel.basic.*.id
  
}
resource "google_monitoring_notification_channel" "basic" {
  display_name = "Webhooksalert"
  type         = "webhook_tokenauth"
  labels = {
  "url"="https://webhook.site/348e676a-b801-4722-9f33-9a0f124eaec5"
  }
}

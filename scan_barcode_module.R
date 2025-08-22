library(shinyjs)

# --- UI Part for Barcode Scanning ---
barcodeScannerUI <- function(id) {
  ns <- NS(id)
  tagList(
    useShinyjs(),
    tags$style(HTML(paste0('#', ns('scanner_wrap'), ' { display: none; position: relative; z-index: 1000; }'))),
    
    # Add audio elements for sounds
    tags$audio(id = ns("beep_success"), src = "www/beep_success.mp3", preload = "auto"),
    tags$audio(id = ns("beep_error"), src = "www/beep_error.mp3", preload = "auto"),
   
    tags$div(
      id = ns("scanner_wrap"),
      style = "width: 100%; max-width: 400px; margin: 0 auto; position: relative; background: #f8f9fa; border-radius: 10px; box-shadow: 0 0 8px #aaa; padding: 10px;",
      tags$div(
        id = ns("video_container"),
        style = "width: 100%; background: #f5f5f5; margin: auto; border-radius: 6px; overflow: hidden;",
        tags$div(id = ns("scanner"), style = "width: 100%; height: 250px;")
      ),
      tags$div(
        id = ns("camera_status"),
        class = "alert alert-info",
        "Camera initializing...",
        style = "margin-top: 8px; display: none;"
      ),
      tags$button(
        id = ns("stop_scan_btn"),
        class = "btn btn-secondary",
        icon = icon("times"),
        "Stop Scan",
        style = "margin-top: 8px; width: 100%;"
      )
    ),

    tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/quagga/0.12.1/quagga.min.js"),
    tags$script(HTML(paste0('
      (function(){
        var lastScan = 0, debounce = 800, scanning = false;
        var scannerWrap = document.getElementById("', ns("scanner_wrap"), '");
        var cameraStatus = document.getElementById("', ns("camera_status"), '");
        var successSound = document.getElementById("', ns("beep_success"), '");
        var errorSound = document.getElementById("', ns("beep_error"), '");
        
        // Pre-load sounds by user interaction to overcome browser restrictions
        document.addEventListener("click", function() {
          if (!successSound.played.length) {
            successSound.volume = 0;
            successSound.play().then(function() {
              successSound.pause();
              successSound.currentTime = 0;
              successSound.volume = 1;
            }).catch(function(e) {
              console.log("Silent preload failed, will try on actual scan:", e);
            });
          }
          if (!errorSound.played.length) {
            errorSound.volume = 0;
            errorSound.play().then(function() {
              errorSound.pause();
              errorSound.currentTime = 0;
              errorSound.volume = 1;
            }).catch(function(e) {
              console.log("Silent preload failed, will try on actual scan:", e);
            });
          }
        }, { once: true });
        
        function showScanner() {
          scannerWrap.style.display = "block";
          cameraStatus.style.display = "block";
          cameraStatus.className = "alert alert-info";
          cameraStatus.textContent = "Initializing camera...";
          scanning = true;
          document.addEventListener("keydown", escListener);
        }
        
        function hideScanner() {
          scannerWrap.style.display = "none";
          scanning = false;
          document.removeEventListener("keydown", escListener);
          if (typeof Quagga !== "undefined") {
            Quagga.stop();
          }
        }
        
        function escListener(e) {
          if (e.key === "Escape") {
            hideScanner();
            Shiny.setInputValue("', ns("stop_scan_btn"), '", Math.random(), {priority: "event"});
          }
        }
        
        function playBeepSuccess() {
          try {
            if (successSound) {
              successSound.currentTime = 0;
              var playPromise = successSound.play();
              if (playPromise !== undefined) {
                playPromise.catch(function(error) {
                  console.error("Error playing success beep:", error);
                });
              }
            }
          } catch(e) {
            console.error("Could not play success beep:", e);
          }
        }
        
        function playBeepError() {
          try {
            if (errorSound) {
              errorSound.currentTime = 0;
              var playPromise = errorSound.play();
              if (playPromise !== undefined) {
                playPromise.catch(function(error) {
                  console.error("Error playing error beep:", error);
                });
              }
            }
          } catch(e) {
            console.error("Could not play error beep:", e);
          }
        }
        
        // Handle stop scan button click
        document.getElementById("', ns("stop_scan_btn"), '").addEventListener("click", function() {
          hideScanner();
          Shiny.setInputValue("', ns("stop_scan_btn"), '", Math.random(), {priority: "event"});
        });
        
        Shiny.addCustomMessageHandler("startScanning", function(message) {
          if (typeof Quagga === "undefined") {
            console.error("Quagga is not loaded");
            cameraStatus.className = "alert alert-danger";
            cameraStatus.textContent = "Error: Barcode scanner library not loaded";
            return;
          }
          
          showScanner();
          
          // First check if camera is available
          if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
            cameraStatus.className = "alert alert-danger";
            cameraStatus.textContent = "Error: Camera access not supported in this browser";
            return;
          }
          
          // Test camera access first
          navigator.mediaDevices.getUserMedia({ 
            video: { 
              facingMode: "environment",
              width: { ideal: 640 },
              height: { ideal: 480 }
            } 
          }).then(function(stream) {
            // Camera access successful, now initialize Quagga
            stream.getTracks().forEach(track => track.stop()); // Stop the test stream
            
            Quagga.init({
              inputStream: {
                name: "Live",
                type: "LiveStream",
                target: document.getElementById("', ns("scanner"), '"),
                constraints: {
                  width: 640,
                  height: 480,
                  facingMode: "environment"
                },
                area: { 
                  top: "0%",    
                  right: "0%",  
                  left: "0%",   
                  bottom: "0%"  
                },
              },
              locator: {
                patchSize: "medium",
                halfSample: true
              },
              numOfWorkers: 2,
              frequency: 10,
              decoder: {
                readers: ["ean_reader", "ean_8_reader", "upc_reader", "code_128_reader"]
              },
              locate: true
            }, function(err) {
              if (err) {
                console.error("Quagga initialization error:", err);
                cameraStatus.className = "alert alert-danger";
                cameraStatus.textContent = "Error initializing camera: " + err;
                playBeepError();
                return;
              }
              console.log("Quagga initialized successfully");
              cameraStatus.className = "alert alert-success";
              cameraStatus.textContent = "Camera ready! Scan a barcode...";
              Quagga.start();
            });
            
            Quagga.offDetected();
            Quagga.onDetected(function(data) {
              var now = Date.now();
              var code = data.codeResult.code;
              if (now - lastScan > debounce && scanning) {
                lastScan = now;
                playBeepSuccess();
                Shiny.setInputValue("', ns("barcode_detected"), '", code, {priority: "event"});
                cameraStatus.className = "alert alert-success";
                cameraStatus.textContent = "Barcode detected: " + code;
              }
            });
            
          }).catch(function(err) {
            cameraStatus.className = "alert alert-danger";
            cameraStatus.textContent = "Camera access denied or error: " + err.message;
            console.error("Camera access error:", err);
          });
        });
        
        Shiny.addCustomMessageHandler("stopScanning", function(message) {
          hideScanner();
        });
      })();
    ')))
  )
}

# --- Server Part to Use the Scanner ---
barcodeScannerServer <- function(id, onBarcodeDetected) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$stop_scan_btn, {
      session$sendCustomMessage("stopScanning", list())
    })
    
    observeEvent(input$barcode_detected, {
      onBarcodeDetected(input$barcode_detected)
    })
  })
}

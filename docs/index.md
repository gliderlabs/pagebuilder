# Foobar

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec elementum massa purus, ut tristique ex ultrices at. Praesent ac diam dui. Nulla facilisi. Nullam faucibus sollicitudin mi non porttitor. In nec imperdiet risus, cursus consequat leo. Nunc sit amet ex sed lacus feugiat elementum quis nec tellus. Praesent at ante non ligula interdum lacinia. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Vivamus ultricies vitae leo quis maximus.

## Foobar Foobar

Nulla dapibus accumsan mi, in porta ex congue viverra. Ut egestas auctor lectus. Fusce urna nulla, vulputate sit amet turpis a, mollis lobortis velit. Praesent ac pulvinar augue, eu iaculis sapien. Morbi sollicitudin lacus ut mauris porta elementum. Sed dapibus, magna congue semper tincidunt, nisi justo bibendum nulla, fermentum pharetra tellus nulla congue dui. Morbi mollis tellus a libero viverra, ut aliquam dui tempus. Curabitur vestibulum elit ultricies porta ultrices. Maecenas blandit, lectus non vestibulum sodales, est lorem sollicitudin libero, in accumsan urna velit vitae metus. Mauris gravida non ante vel consectetur. Vestibulum finibus suscipit magna, vel fermentum est rutrum vitae. Donec luctus condimentum imperdiet.

```
package httpstream

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"

	"code.google.com/p/go.net/websocket"
	"github.com/gorilla/mux"

	"github.com/gliderlabs/logspout/router"
)

func init() {
	router.HttpHandlers.Register(LogStreamer, "logs")
}

func debug(v ...interface{}) {
	if os.Getenv("DEBUG") != "" {
		log.Println(v...)
	}
}

func LogStreamer() http.Handler {
	logs := mux.NewRouter()
	logsHandler := func(w http.ResponseWriter, req *http.Request) {
		params := mux.Vars(req)
		route := new(router.Route)

		if params["value"] != "" {
			switch params["predicate"] {
			case "id":
				route.FilterID = params["value"]
				if len(route.ID) > 12 {
					route.FilterID = route.FilterID[:12]
				}
			case "name":
				route.FilterName = params["value"]
			}
		}

		if route.FilterID != "" && !router.Routes.RoutingFrom(route.FilterID) {
			http.NotFound(w, req)
			return
		}

		defer debug("http: logs streamer disconnected")
		logstream := make(chan *router.Message)
		defer close(logstream)

		var closer <-chan bool
		if req.Header.Get("Upgrade") == "websocket" {
			debug("http: logs streamer connected [websocket]")
			closerBi := make(chan bool)
			defer websocketStreamer(w, req, logstream, closerBi)
			closer = closerBi
		} else {
			debug("http: logs streamer connected [http]")
			defer httpStreamer(w, req, logstream, route.MultiContainer())
			closer = w.(http.CloseNotifier).CloseNotify()
		}
		route.OverrideCloser(closer)

		router.Routes.Route(route, logstream)
	}
	logs.HandleFunc("/logs/{predicate:[a-zA-Z]+}:{value}", logsHandler).Methods("GET")
	logs.HandleFunc("/logs", logsHandler).Methods("GET")
	return logs
}

type Colorizer map[string]int

// returns up to 14 color escape codes (then repeats) for each unique key
func (c Colorizer) Get(key string) string {
	i, exists := c[key]
	if !exists {
		c[key] = len(c)
		i = c[key]
	}
	bright := "1;"
	if i%14 > 6 {
		bright = ""
	}
	return "\x1b[" + bright + "3" + strconv.Itoa(7-(i%7)) + "m"
}

func marshal(obj interface{}) []byte {
	bytes, err := json.MarshalIndent(obj, "", "  ")
	if err != nil {
		log.Println("marshal:", err)
	}
	return bytes
}

func normalName(name string) string {
	return name[1:]
}

func websocketStreamer(w http.ResponseWriter, req *http.Request, logstream chan *router.Message, closer chan bool) {
	websocket.Handler(func(conn *websocket.Conn) {
		for logline := range logstream {
			if req.URL.Query().Get("source") != "" && logline.Source != req.URL.Query().Get("source") {
				continue
			}
			_, err := conn.Write(append(marshal(logline), '\n'))
			if err != nil {
				closer <- true
				return
			}
		}
	}).ServeHTTP(w, req)
}

func httpStreamer(w http.ResponseWriter, req *http.Request, logstream chan *router.Message, multi bool) {
	var colors Colorizer
	var usecolor, usejson bool
	nameWidth := 16
	if req.URL.Query().Get("colors") != "off" {
		colors = make(Colorizer)
		usecolor = true
	}
	if req.Header.Get("Accept") == "application/json" {
		w.Header().Add("Content-Type", "application/json")
		usejson = true
	} else {
		w.Header().Add("Content-Type", "text/plain")
	}
	for logline := range logstream {
		if req.URL.Query().Get("sources") != "" && logline.Source != req.URL.Query().Get("sources") {
			continue
		}
		if usejson {
			w.Write(append(marshal(logline), '\n'))
		} else {
			if multi {
				name := normalName(logline.Container.Name)
				if len(name) > nameWidth {
					nameWidth = len(name)
				}
				if usecolor {
					w.Write([]byte(fmt.Sprintf(
						"%s%"+strconv.Itoa(nameWidth)+"s|%s\x1b[0m\n",
						colors.Get(name), name, logline.Data,
					)))
				} else {
					w.Write([]byte(fmt.Sprintf(
						"%"+strconv.Itoa(nameWidth)+"s|%s\n", name, logline.Data,
					)))
				}
			} else {
				w.Write(append([]byte(logline.Data), '\n'))
			}
		}
		w.(http.Flusher).Flush()
	}
}
```

Nullam rutrum nisi non velit iaculis, eu condimentum nibh placerat. Cras eu urna eu nunc pharetra gravida non id ex. Vestibulum at dictum sapien. Quisque tristique, erat pretium venenatis fermentum, sapien mauris suscipit arcu, nec sollicitudin dui diam vel ipsum. Duis eleifend nisi id ultricies imperdiet. Sed viverra metus vel mi tincidunt cursus. Suspendisse nulla risus, aliquam at mollis vitae, porttitor sed quam. Sed sit amet magna tortor. Suspendisse potenti. Phasellus ante orci, sagittis tincidunt luctus sit amet, dapibus vitae augue. Maecenas elementum dignissim augue eu dignissim. Integer molestie, sem quis rhoncus semper, lectus diam sollicitudin ligula, vel euismod tellus tortor non libero. Phasellus ac nibh vitae nulla varius porta eu vitae mauris. Morbi mattis tincidunt arcu et dapibus.

Maecenas iaculis est dignissim leo lobortis varius. Aliquam at condimentum enim. Cras et tincidunt enim. In quis dapibus magna. Sed sed tellus sem. Curabitur vel justo leo. Sed eget tincidunt nisl. Sed nec lacus at massa sollicitudin bibendum vel vel nibh. Vivamus finibus erat vel tempor rutrum.

Cras blandit imperdiet sem, vel viverra est tincidunt sed. Sed sapien dui, pretium in ornare in, semper vel orci. Maecenas a quam velit. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Nulla egestas, diam id venenatis porta, mauris massa hendrerit felis, eu tristique leo urna egestas tortor. Vestibulum vel turpis ante. Etiam vulputate in lectus ut lobortis. Aenean semper, tellus lacinia porttitor dapibus, diam nibh rhoncus quam, vitae interdum sapien eros quis augue. Nam id odio suscipit, congue velit vel, maximus ligula. Vestibulum feugiat fringilla posuere.

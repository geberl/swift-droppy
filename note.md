drag-and-drop kann ich ja grundsätzlich mit mehr als nur files machen in macos, oder???
mit was noch? urls? selected text? sprich auf welche alternativen werte kann ich das "accept" meines event handlers setzen?

---

jeder task sollte spezifizieren was er alles akzeptiert (in)
und was er aus dem dann macht (out)

z.B. "rotate"
	in -> n (jpg, png, tiff, bmp), out -> n (jpg, png, tiff, bmp)
	in -> n (any other extention), out -> (nothing)
	in -> n (folders), out -> (nothing)
z.B. "compress"
	in -> n (any extention), out -> 1 (zip)
	in -> n (folders), out -> (nothing)

das vermeidet für den user von einem task der nur dateien rausgibt in einen task der nur ordner akzeptiert zu pipen (z.B. dann rot machen in GUI)

und ich kann meine building blocks (tasks) mit kleinen symbolen anreichern (ordner icon durchgestrichen, file icon aktiv mit extentions als mouseover)

---
	
der jeweils erste task des workflows der gerade aktiv ist sollte bestimmen was ich auf das drag-and-drop target ablegen kann (mouse cursor entsprechend)

der user soll aber rückmeldung bekommen, warum das denn jetzt nicht geht, nicht einfach ohne feedback verbieten

z.b in bzw. direkt auf dem target (statt dem symbol des workflows) sollte dann text erscheinen ("workflow only supports files")

---

ich nehme an im ios share sheet wird nicht mit dateien gearbeitet, hier müsste man halt dann einen weg finden was auch immer gerade geshared wurde als ersten schritt in eine datei zu überführen (App Name: SharPy?)

identisch auch bei der macos clipboard-variante des tools (CopPy); hier muss aus dem was grad im clipboard ist im ersten schritt eine geeignete datei erzeugt werden (png, txt, richtext, ...)

dann könnte man mit den üblichen tasks auf dateibasis fortfahren

beim letzten schritt wirds bei iOS nochmal spannend, jetzt das was bislang als datei vorlag wie auch immer es benötigt wird über das share sheet rausgeben, für eine beliebige bzw. bestimmte andere app (welche app geeignet ist ergibt sich wohl irgendwie über den datentyp, siehe "workflow" app)

bei der clipboard-variante kann man als default anbieten das endergebnis als letzten schritt in das clipboard zurückzuschreiben; wobei das auch bei DropPy/SharPy sinn machen kann; z.B. um image metadata als text zurückzubekommen (height/width/resolution); oder um die url des bildes das man gerade an imgur hochgeladen hat gleich in der zwischenablage zu haben

---

key question: how do you actually provide the python language on ios?

https://bugs.python.org/issue23670
	start here

http://omz-software.com/pythonista/
	http://omz-software.com/pythonista/docs/copyright.html
		keine hinweise auf externe module die das zum kompilieren bringen

http://pythonforios.com/

https://github.com/linusyang/python-for-ios
	bester hinweis
	https://github.com/jdelman/python-for-ios/commit/83381dc9847e5de29f697668ff6feb0ba887fe82
	
http://www.saurik.com/id/5
	vielleicht ist auch das hilfreich

https://github.com/gregneagle/Xcode4CocoaPythonTemplates
http://stackoverflow.com/questions/5843508/pyobjc-on-xcode-4/5860455#5860455
	unklar

https://stackoverflow.com/questions/20024121/integrating-livecode-native-apps-with-python-apps-via-network-sockets-on-mobile
	macht wenig hoffnung

https://lukasa.co.uk/2016/12/Python_on_iOS/
	scheint guter artikel zu sein, aber unklar ob für mich hilfreich
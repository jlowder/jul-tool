(defsystem jul-tool
    :name "com.lowdermilk.jul-tool"
    :version "1.0.0"
    :author "Jason Lowdermilk"
    :description "Interactive Julian Date Calculator"
    :long-description "Simple command-line tool for converting to and from julian dates, and other date-related functions."
    :serial t
    :depends-on (:julian
                 :prompt)
    :components ((:file "jul-tool")))

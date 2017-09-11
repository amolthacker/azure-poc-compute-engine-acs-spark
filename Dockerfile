FROM amolthacker/dcos-spark-ql

ENTRYPOINT ["./bin/spark-submit", "--class", "com.td.veritas.valengine.spark.Valengine", "--master", "local[3]", \
            "--driver-library-path", "/usr/local/lib", "--conf", "spark.executor.extraLibraryPath=/usr/local/lib", \
            "/opt/spark/dist/compute-engine-spark-0.1.0.jar", "NPV", "40", "4"]

ADD target/compute-engine-spark-0.1.0.jar .
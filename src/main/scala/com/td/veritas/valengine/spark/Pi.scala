package com.td.veritas.valengine.spark

/**
  * Created by Amol on 5/9/17.
  */
import com.esotericsoftware.kryo.Kryo

import scala.math.min
import scala.math.random

import org.apache.spark.sql.SparkSession

/** Computes an approximation to pi */
object Pi {
  def main(args: Array[String]) {
    val spark = SparkSession
      .builder
      //.master("local")
      .appName("Spark Pi")
      .getOrCreate()
    val slices = if (args.length > 0) args(0).toInt else 2
    val n = min(100000L * slices, Int.MaxValue).toInt // avoid overflow
    val count = spark.sparkContext.parallelize(1 until n, slices).map { i =>
      val x = random * 2 - 1
      val y = random * 2 - 1
      if (x*x + y*y <= 1) 1 else 0
    }.reduce(_ + _)
    println(s"Pi is roughly ${4.0 * count / (n - 1)}")
    spark.stop()
  }

}
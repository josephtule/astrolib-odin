package sandbox

import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:thread"
import "core:time"


NUM_THREADS := os.processor_core_count() - 1

Point :: struct {
	x: f32,
	y: f32,
}

main :: proc() {
	numPoints := 10
	numIterations := 100
	fmt.println("Mutli-threaded:")
	{
		points := make([]Point, numPoints)
		defer delete(points)

		start: time.Time
		end: time.Time
		// Add tasks to thread pool

		// Initialize thread pool
		pool: thread.Pool
		thread.pool_init(&pool, context.allocator, NUM_THREADS)
		thread.pool_start(&pool)
		start = time.now()
		for j in 0 ..< numIterations {
			for i in 0 ..< numPoints {
				thread.pool_add_task(
					&pool,
					context.allocator,
					thread_update_point,
					&points[i],
					i,
				)
			}
			// Wait for all tasks to complete
			thread.pool_finish(&pool)
		}
		defer thread.pool_destroy(&pool)
		end = time.now()
		fmt.println(time.duration_milliseconds(time.diff(start, end)))
		// // Print updated points
		// for i in 0 ..< numPoints {
		// 	fmt.println(points[i].x)
		// }
	}
	fmt.println("Single Threaded")
	{
		points := make([]Point, numPoints)
		defer delete(points)

		start: time.Time
		end: time.Time
		// Add tasks to thread pool
		start = time.now()
		for j in 0 ..< numIterations {
			for i in 0 ..< numPoints {
				update_point(&points[i])
			}
		}
		end = time.now()
		fmt.println(time.duration_milliseconds(time.diff(start, end)))
		// // Print updated points
		// for i in 0 ..< numPoints {
		// 	fmt.println(points[i].x)
		// }
	}

}

thread_update_point :: proc(task: thread.Task) {
	point := cast(^Point)task.data
	update_point(point)
}

update_point :: proc(point: ^Point) {
	// vel := [2]f32{1, 1}
	vel := [2]f32{rand.float32_normal(0, 1), rand.float32_normal(0, 1)}
	// time.sleep(10 * time.Millisecond)
	point.x += vel.x
	point.y += vel.y
}

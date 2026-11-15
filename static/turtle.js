/* Mini "turtle" for org source blocks.
 *
 * The org block is assigned a name with #+NAME: block-name.
 * The code is executed with a turtle object ~t~ and the result
 * is displayed on a <canvas class="turtle" data-src="block-name">.
 */
function makeTurtle() {
  const parts = [];
  let x = 0, y = 0, a = 0;
  return {
    parts,
    forward(d) {
      const nx = x + d * Math.cos(a), ny = y + d * Math.sin(a);
      parts.push(line(x, y, nx, ny));
      x = nx; y = ny;
    },
    circle(r) {
        // Do the circle similar to how python turtle does it:
        // x, y is the point on the circumference of the circle, and r is the radius.
        // the direction of the circle is determined by the current heading of the turtle (the angle a).
        const centerX = x - r * Math.cos(a);
        const centerY = y - r * Math.sin(a);
        parts.push(circle(centerX, centerY, r));
    },
    goto(nx, ny) {
        x = nx;
        y = ny;
    },
    right(deg) { a += deg * Math.PI / 180; },
    left(deg) { a -= deg * Math.PI / 180; },
  };
}

function line(x1, y1, x2, y2) {
    return {
        draw(context) {
            context.beginPath();
            context.moveTo(x1, y1);
            context.lineTo(x2, y2);
            context.stroke();
        }
    };
}

function circle(x, y, r, a) {
    return {
        draw(context) {
            context.beginPath();
            context.arc(x, y, r, 0, 2 * Math.PI);
            context.stroke();
        }
    };
}

document.querySelectorAll('canvas.turtle').forEach((canvas) => {
  // Find the block(s) with the code related to this canvas.
  // Blocks have the same ID as cavas's data-src attribute.
  // I know, it is illegal to have multiple elements with the same ID, but it is simple.
  // Practically, this is a simple way to have multiple turtles working on the same canvas.
  const blocks = document.querySelectorAll(`#${canvas.dataset.src}`);
  const turtles = [...blocks].map((block) => {
    const t = makeTurtle();
    const code = block.textContent;
    const func = new Function('t', code);
    func(t);
    return t;
  });

  // Draw the parts created by the turtle on the canvas.
  const context = canvas.getContext('2d');
  context.translate(canvas.width / 2, canvas.height / 2);
  let i = 0;
  (function step() {
    turtles.forEach((t) => {
      if (i >= t.parts.length) return;
      t.parts[i++].draw(context);
    });
    requestAnimationFrame(step);
  })();

  // The simple version with one turtle per canvas:
  // const t = makeTurtle();
  // const code = block.textContent;
  // const func = new Function('t', code);
  // // Execute the code with the turtle object as argument.
  // func(t);

  // // Draw the segments created by the turtle on the canvas.
  // const context = canvas.getContext('2d');
  // context.translate(canvas.width / 2, canvas.height / 2);
  // let i = 0;
  // (function step() {
  //   if (i >= t.parts.length) return;
  //   t.parts[i++].draw(context);
  //   requestAnimationFrame(step);
  // })();
});

# Gulpfile
------

Require some libs.

    path = require 'path'
    gulp = require 'gulp'
    browserify = require 'gulp-browserify'
    coffee = require 'gulp-coffee'
    coffeelint = require 'gulp-coffeelint'
    header = require 'gulp-header'
    rename = require 'gulp-rename'
    uglify = require 'gulp-uglify'
    license = require 'gulp-license'
    gzip = require 'gulp-gzip'
    runSequence = require 'run-sequence'
    pkg = require path.join __dirname, 'package.json'

Create the banner for insertion in headers.

    banner = [
        '/*!'
        '<%= pkg.name %> v<%= pkg.version %>'
        ' | @license <%= pkg.license %>'
        '*/'].join ' '
    banner += '\n'

Set up paths.

    paths =
      coffeescript: path.join '.', 'src', '**', '*.litcoffee'
      dist: path.join '.', 'dist'

## lint
-----

Run lint on coffeescript files.

    gulp.task 'lint', ()->
      gulp.src(
        paths.coffeescript
      ).pipe(
        coffeelint()
      ).pipe(
        coffeelint.reporter 'fail'
      )

## compile
-----

Call `lint`, then compile coffeescript to JS.

    gulp.task 'compile', ['lint'], ()->
      return gulp.src(
        paths.coffeescript
      ).pipe(
        coffee()
      ).pipe(
        uglify()
      ).pipe(
        gzip()
      ).pipe(
        rename "png-baker.min.js"
      ).pipe(
        gulp.dest paths.dist
      )

## write_license
-----

Write license to header of compiled js.

    gulp.task 'write_license', ()->
      return gulp.src(
        path.join paths.dist, 'png-baker.min.js'
      ).pipe(
        license pkg.license, {tiny: true, organization: pkg.organization}
      ).pipe(
        gulp.dest paths.dist
      )

## default
-----

Default gulp task. Calls `compile`, then `write_license`.

    gulp.task 'default', ()->
    runSequence(
      [
        'compile'
      ],
      [
        'write_license'
      ]
    )
var gulp = require("gulp");
var ts = require("gulp-typescript");
var tsProject = ts.createProject("tsconfig.json");
var coffeescript = require('gulp-coffeescript');
var sourcemaps = require('gulp-sourcemaps');

gulp.task("coffee", function() {
  gulp.src('src/**/*.coffee')
    .pipe(coffeescript({bare: true}))
    .pipe(gulp.dest('dist'));
});

gulp.task("resources", function() {
  gulp.src(['src/**/*.json', 'src/**/*.pug', ])
    .pipe(gulp.dest('dist'));
});

gulp.task("default", ['coffee', 'resources'], function () {

  var tsResult = gulp.src('src/**/*.ts')
    .pipe(sourcemaps.init())
    .pipe(tsProject());

  return tsResult
    .pipe(sourcemaps.write('.', {
      sourceRoot: function(file) { return file.cwd + '/src'; }
    }))
    .pipe(gulp.dest("dist"));
});

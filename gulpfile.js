'use strict';

var gulp = require('gulp'),
    angularFileSort = require('gulp-angular-filesort'),
    concat = require('gulp-concat'),
    wrapper = require('gulp-wrapper'),
    rename = require('gulp-rename'),
    uglify = require('gulp-uglify'),
    sass = require('gulp-sass'),
    notify = require('gulp-notify'),
    ngAnnotate = require('gulp-ng-annotate');

gulp.task('compile-js', function () {
  return gulp.src('assets/javascripts/**/*.js')
    .pipe(angularFileSort())
    .pipe(concat('application.js'))
    .pipe(ngAnnotate({
      add: true,
      single_quotes: true
    }))
    .pipe(wrapper({
      header: '(function(window, document) {\n',
      footer: '\n})(window, document);'
    }))
    .pipe(gulp.dest('dist'))
    .pipe(rename('application.min.js'))
    .pipe(uglify())
    .pipe(gulp.dest('public/javascripts'))
    .pipe(notify('Javascript compilation completed successfully'));
});

gulp.task('compile-js-dev', function () {
  return gulp.src('assets/javascripts/**/*.js')
    .pipe(angularFileSort())
    .pipe(concat('application.js'))
    .pipe(wrapper({
      header: '(function(window, document) {\n',
      footer: '\n})(window, document);'
    }))
    .pipe(gulp.dest('dist'))
    .pipe(gulp.dest('public/javascripts'))
    .pipe(notify('Javascript compilation completed successfully'));
});

gulp.task('sass', function() {
  return gulp.src('assets/stylesheets/**/*.scss')
    .pipe(sass())
    .pipe(concat('application.css'))
    .pipe(gulp.dest('public/stylesheets'))
    .pipe(notify('Sass compilation completed successfully'));
});

gulp.task('watch', function() {
  gulp.watch('assets/javascripts/**/*.js', ['compile-js-dev']);
  gulp.watch('assets/stylesheets/**/*.scss', ['sass']);
});

gulp.task('dev', ['compile-js-dev', 'sass', 'watch']);

gulp.task('default', ['compile-js', 'sass']);

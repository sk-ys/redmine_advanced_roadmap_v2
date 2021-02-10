require_dependency "redmine/helpers/gantt"

class MilestoneLabel
  def id
    @project_id
  end
  def initialize(project_id=0)
    @project_id = project_id
  end
end

module AdvancedRoadmap
  module RedmineHelpersGanttPatch
    def render_version(project, version, options = {})
      if @last_rendered_project_and_only != "#{project}-#{options[:only]}" and
        project.milestones.any? and
        options[:only] != :selected_columns

        # Render milestones label
        if @last_rendered_project != project
          subject_for_milestones_label(options, MilestoneLabel.new(project.id))
        end

        # Render milestones
        options[:top] += options[:top_increment]
        @number_of_rows += 1
        options[:indent] += options[:indent_increment]
        project.milestones.sort.each do |milestone|
          render_milestone(project, milestone, options)
        end
        options[:indent] -= options[:indent_increment]
      end
      @last_rendered_project_and_only = "#{project}-#{options[:only]}"
      @last_rendered_project = project
      super(project, version, options)
    end

    def render_milestone(project, milestone, options = {})
      # Milestone header
      subject_for_milestone(milestone, options) unless options[:only] == :lines
      line_for_milestone(milestone, options) unless options[:only] == :subjects
      options[:top] += options[:top_increment]
      @number_of_rows += 1
    end

    def subject_for_milestones_label(options, milestone_label)
      case options[:format]
      when :html
        html_class = 'icon icon-milestones'
        s = l(:label_milestone_plural)
        subject = view.content_tag(:span, s, :class => html_class).html_safe
        if Redmine::VERSION::MAJOR >= 4
          html_subject(options, subject, milestone_label)
        else
          html_subject(options, subject, :css => "milestones-label")
        end
      when :image
        image_subject(options, l(:label_milestone_plural))
      when :pdf
        pdf_new_page?(options)
        pdf_subject(options, l(:label_milestone_plural))
      end
    end

    def subject_for_milestone(milestone, options)
      case options[:format]
      when :html
        html_class = 'icon icon-milestone'
        s = view.link_to_milestone(milestone).html_safe
        subject = view.content_tag(:span, s, :class => html_class).html_safe
        if Redmine::VERSION::MAJOR >= 4
          html_subject(options, subject, milestone)
        else
          html_subject(options, subject, :css => "milestone-name")
        end
      when :image
        image_subject(options, milestone.to_s)
      when :pdf
        pdf_new_page?(options)
        pdf_subject(options, milestone.to_s)
      end
    end

    def line_for_milestone(milestone, options)
      # Skip milestones that don't have an effective date
      if milestone.is_a?(Milestone) && milestone.effective_date
        options[:zoom] ||= 1
        options[:g_width] ||= (self.date_to - self.date_from + 1) * options[:zoom]
        coords = coordinates_point(milestone.effective_date, options[:zoom])
        label = "#{h(milestone)}"
        markers = true

        if Redmine::VERSION::MAJOR >= 4
          send "#{options[:format]}_task", options, coords, markers, label, milestone
        else
          case options[:format]
          when :html
            if Redmine::VERSION::MAJOR == 2
              html_task(options, coords, :css => "version task", :label => label, :markers => true)
            else
              html_task(options, coords, true, label, Version)
            end
          when :image
            if Redmine::VERSION::MAJOR == 2
              image_task(options, coords, :label => label, :markers => true, :height => 3)
            else
              image_task(options, coords, true, label, Version)
            end
          when :pdf
            if Redmine::VERSION::MAJOR == 2
              pdf_task(options, coords, :label => label, :markers => true, :height => 0.8)
            else
              pdf_task(options, coords, true, label, Version)
            end
          end
        end
      else
        ActiveRecord::Base.logger.debug "Gantt#line_for_milestone was not given a milestone with an effective_date"
        ""
      end
    end

    def number_of_rows_on_project(project)
      count = super(project)
      return 0 unless projects.include?(project)
      if project.milestones.any?
        count += 1
        count += project.milestones.size
      end
    end

    def html_subject(params, subject, object)
      # TODO: need `has_children = True`, if use expander
      super(params, subject, object)
    end

    private

      def coordinates_point(date, zoom = nil)
        zoom ||= @zoom
        coords = {}
        if date && (self.date_from < date) && (self.date_to > date)
          coords[:start] = date - self.date_from
          coords[:end] = coords[:start] - 1
          coords[:bar_start] = coords[:bar_end] = date - self.date_from
        end
        # Transforms dates into pixels witdh
        coords.keys.each do |key|
          coords[key] = ((coords[key] * zoom) + (zoom.to_f / 2.0)).floor
        end
        return(coords)
      end
  end
end

# module AdvancedRoadmap
#   module RedmineHelpersGanttPatch
#     def self.included(base)
#       base.class_eval do

#         def render_version_with_milestones(project, version, options = {})
#           if @last_rendered_project != project and project.milestones.any?
#             subject_for_milestones_label(options)
#             options[:top] += options[:top_increment]
#             @number_of_rows += 1
#             options[:indent] += options[:indent_increment]
#             project.milestones.sort.each do |milestone|
#               render_milestone(project, milestone, options)
#             end
#             options[:indent] -= options[:indent_increment]
#           end
#           @last_rendered_project = project
#           render_version_without_milestones(project, version, options)
#         end
        
#         alias_method :render_version_withtout_milestones, :render_version
#         alias_method :render_version, :render_version_with_milestones

#         def render_milestone(project, milestone, options = {})
#           # Milestone header
#           subject_for_milestone(milestone, options) unless options[:only] == :lines
#           line_for_milestone(milestone, options) unless options[:only] == :subjects
#           options[:top] += options[:top_increment]
#           @number_of_rows += 1
#         end

#         def subject_for_milestones_label(options)
#           case options[:format]
#           when :html
#             html_class = 'icon icon-milestones'
#             s = l(:label_milestone_plural)
#             subject = view.content_tag(:span, s, :class => html_class).html_safe
#             html_subject(options, subject, :css => "milestones-label")
#           when :image
#             image_subject(options, l(:label_milestone_plural))
#           when :pdf
#             pdf_new_page?(options)
#             pdf_subject(options, l(:label_milestone_plural))
#           end
#         end

#         def subject_for_milestone(milestone, options)
#           case options[:format]
#           when :html
#             html_class = 'icon icon-milestone'
#             s = view.link_to_milestone(milestone).html_safe
#             subject = view.content_tag(:span, s, :class => html_class).html_safe
#             html_subject(options, subject, :css => "milestone-name")
#           when :image
#             image_subject(options, milestone.to_s)
#           when :pdf
#             pdf_new_page?(options)
#             pdf_subject(options, milestone.to_s)
#           end
#         end

#         def line_for_milestone(milestone, options)
#           # Skip milestones that don't have an effective date
#           if milestone.is_a?(Milestone) && milestone.effective_date
#             options[:zoom] ||= 1
#             options[:g_width] ||= (self.date_to - self.date_from + 1) * options[:zoom]
#             coords = coordinates_point(milestone.effective_date, options[:zoom])
#             label = "#{h(milestone)}"
#             case options[:format]
#             when :html
#               if Redmine::VERSION::MAJOR == 2
#                 html_task(options, coords, :css => "version task", :label => label, :markers => true)
#               else
#                 html_task(options, coords, true, label, Version)
#               end
#             when :image
#               if Redmine::VERSION::MAJOR == 2
#                 image_task(options, coords, :label => label, :markers => true, :height => 3)
#               else
#                 image_task(options, coords, true, label, Version)
#               end
#             when :pdf
#               if Redmine::VERSION::MAJOR == 2
#                 pdf_task(options, coords, :label => label, :markers => true, :height => 0.8)
#               else
#                 pdf_task(options, coords, true, label, Version)
#               end
#             end
#           else
#             ActiveRecord::Base.logger.debug "Gantt#line_for_milestone was not given a milestone with an effective_date"
#             ""
#           end
#         end

#       private

#         def coordinates_point(date, zoom = nil)
#           zoom ||= @zoom
#           coords = {}
#           if date && (self.date_from < date) && (self.date_to > date)
#             coords[:start] = date - self.date_from
#             coords[:end] = coords[:start] - 1
#             coords[:bar_start] = coords[:bar_end] = date - self.date_from
#           end
#           # Transforms dates into pixels witdh
#           coords.keys.each do |key|
#             coords[key] = ((coords[key] * zoom) + (zoom.to_f / 2.0)).floor
#           end
#           return(coords)
#         end

#       end
#     end
#   end
# end

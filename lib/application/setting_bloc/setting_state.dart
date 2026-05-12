part of 'setting_bloc.dart';

@immutable
abstract class SettingState extends Equatable {
  const SettingState();

  @override
  List<Object> get props => [];
}

class SettingInitial extends SettingState {}

class SettingLoading extends SettingState {}

class SettingLoaded extends SettingState {
  final TermsConditionModel model;

  const SettingLoaded(this.model);
}

class SettingFailed extends SettingState {
  final String message;

  const SettingFailed(this.message);
}

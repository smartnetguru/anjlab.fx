using System;

namespace AnjLab.FX.Tasks.Scheduling
{
    internal class DailyTrigger: ITrigger
    {
        private readonly string _tag;
        private readonly TimeSpan _timeOfDay;

        public DailyTrigger(string tag, TimeSpan timeOfDay)
        {
            _tag = tag;
            _timeOfDay = timeOfDay;
        }

        public DateTime? GetNextTriggerTime(DateTime currentTime)
        {
            DateTime date = currentTime.Date;
            if (currentTime.TimeOfDay <= _timeOfDay)
                return date.Add(_timeOfDay);
            else
                return date.AddDays(1).Add(_timeOfDay);
        }

        public string Tag
        {
            get { return _tag; }
        }

        public TimeSpan TimeOfDay
        {
            get { return _timeOfDay; }
        }

        public override string ToString()
        {
            return string.Format("[{1}] Daily at {0}", _timeOfDay, _tag);
        }
    }
}